# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import os.path as op
import shutil
import json
import sys

from .compat import iteritems, reraise, to_unicode
from .container import Container
from .utils import (check_tarball, check_git, check_url, download_file,
                    git_pull_or_clone, touch, slugify)

import click


def execute(ctx, user, hostname, cmd, workdir, tty=False):
    node_name = ''.join([i for i in hostname if not i.isdigit()])
    nodes = ("frontend", "services", "node", "server", "rsyslog")
    if node_name not in nodes:
        raise click.ClickException("Cannot find the container with the name "
                                   "'%s'" % hostname)
    containers = dict((c.hostname, c) for c in ctx.docker.get_containers())
    if hostname not in containers.keys():
        raise click.ClickException("The container must be started before "
                                   "running this command. Run  `oardocker"
                                   " start` first")
    user_cmd = ' '.join(cmd)
    return containers[hostname].execute(user_cmd, user, workdir, tty)


def check_images_requirements(ctx, nodes, needed_tag, parent_cmd):
    available_images = [', '.join(im["RepoTags"]) for im in
                        ctx.docker.get_images(all_images=False)]
    all_images = list(set([', '.join(im["RepoTags"]) for im in
                           ctx.docker.get_images(all_images=True)]))
    no_missings_images = set()
    needed_images = set([ctx.image_name(node, needed_tag) for node in nodes])
    for image in needed_images:
        for available_image in available_images:
            if image in available_image:
                no_missings_images.add(image)
    missings_images = list(set(needed_images) - set(no_missings_images))
    if missings_images:
        for image in missings_images:
            red_image_name = click.style(image, fg="red")
            blue_image_name = click.style(image, fg="blue")
            if image in all_images:
                click.echo("Attached '%s' image to the workdir"
                           % blue_image_name)
                ctx.docker.add_image(image)
            else:
                pull_error = None
                rl = "'\x1b[2K\r"
                bar_template = '[%(bar)s] %(label)s %(info)s'
                label = "Pulling '%s'\t" % blue_image_name
                pull_generator = ctx.docker.api.pull(image, stream=True)
                with click.progressbar(pull_generator,
                                       bar_template=bar_template,
                                       label=label) as stream:
                    for line in stream:
                        dline = json.loads(to_unicode(line))
                        if "error" in dline:
                            click.echo(rl + dline['error'], nl=False)
                            pull_error = dline['error']
                click.echo("'\x1b[2K\r", nl=False)
                if not pull_error:
                    ctx.docker.add_image(image)
                    missings_images = list(set(missings_images) -
                                           set([image]))
                else:
                    click.echo(pull_error)

    if missings_images:
        for image in missings_images:
            red_image_name = click.style(image, fg="red")
            click.echo("missing image '%s'" % red_image_name)
        raise click.ClickException("You need build missing images first, with "
                                   "`%s` command" % parent_cmd)


def install(ctx, src, needed_tag, tag, parent_cmd):
    install_script = ctx.state.manifest['install_script']
    if not install_script:
        raise click.ClickException("This operation is not supported for "
                                   "this env")
    nodes = ctx.state.manifest['install_on']
    soft_name = ctx.state.manifest['install_software_name']
    soft_slug = slugify(soft_name)
    check_images_requirements(ctx, nodes, needed_tag, parent_cmd)
    if not op.exists(ctx.postinstall_dir):
        os.makedirs(ctx.postinstall_dir)
    is_git = False
    is_tarball = False
    is_remote = False
    if op.exists(src):
        src = op.realpath(src)
        is_tarball = check_tarball(src)
        is_git = check_git(src)
    else:
        if src.startswith("git+"):
            src = src[4:]
            is_git = True
            is_remote = True
        elif check_url(src):
            is_remote = True
            is_tarball = True
    if not is_tarball and not is_git:
        raise click.ClickException("Invalid src '%s'. Must be a tarball or a"
                                   " git repository" % src)
    if is_remote:
        ctx.log("Fetching '%s' src from %s..." % (soft_name, src))
        if is_git:
            path = op.join(ctx.postinstall_dir, "%s-git" % soft_slug)
            git_pull_or_clone(src, path)
        else:
            path = op.join(ctx.postinstall_dir,
                           "%s-tarball.tar.gz" % soft_slug)
            download_file(src, path)
    else:
        path = src
    ctx.log("Installing '%s' from %s" % (soft_name, src))
    postinstall_cpath = "/tmp/postintall"
    if is_git:
        src_cpath = "%s/%s-git" % (postinstall_cpath, soft_slug)
    else:
        src_cpath = "%s/tarballs/%s-tarball.tar.gz" % (postinstall_cpath,
                                                       soft_slug)
    binds = {path: {'bind': src_cpath, 'ro': True}}
    command = [install_script, src_cpath]
    volumes = []
    for path, bind in iteritems(binds):
        if bind["ro"]:
            mount_option = "ro"
        else:
            mount_option = "rw"
        volumes.append("-v")
        volumes.append("%s:%s:%s" % (path, bind["bind"], mount_option))
    max_prefix_width = max([len(n) for n in nodes])
    for node in nodes:
        container_name = ctx.docker.generate_container_name()
        image = ctx.image_name(node, needed_tag)
        cli_options = ["run", "-a", "STDOUT", "-a", "STDERR", "--device", "/dev/fuse", "--cap-add", "SYS_ADMIN", "--security-opt", "apparmor:unconfined", "--name", container_name]
        cli_options.extend(volumes)
        cli_options.extend([image] + command)
        ctx.state["containers"].append(container_name)

        padding = ' ' * (max_prefix_width - len(node))
        prefix = click.style(''.join([padding, node, ' | ']), fg="green")

        try:
            for line in ctx.docker.cli(cli_options, _iter=True):
                ctx.log(prefix + line, nl=False)
        except:
            container = Container.from_name(ctx.docker, container_name)
            container.remove(v=False, link=False, force=True)
            exc_type, exc_value, tb = sys.exc_info()
            reraise(exc_type, exc_value, tb.tb_next)

        container = Container.from_name(ctx.docker, container_name)
        oar_version = container.logs().strip().split('\n')[-1]
        repository = ctx.image_name(node)
        commit = container.commit(repository=repository, tag=tag,
                                  message=oar_version)
        ctx.docker.save_image(commit['Id'], tag=tag, repository=repository)
        ctx.state["images"].append(commit['Id'][:12])
        container.remove(v=False, link=False, force=True)


def log_started(hostname):
    started = click.style("Started", fg="green")
    click.echo("Container %s --> %s" % (hostname, started))


def get_common_binds(ctx, hostname):
    paths = (
        '/root/.bash_history',
        '/root/.pyhistory',
        '/home/docker/.bash_history',
        '/home/docker/.pyhistory',
    )
    binds = {}
    for container_path in paths:
        host_path = op.join(ctx.tmp_workdir, hostname) + container_path
        if op.exists(host_path):
            if op.isdir(host_path):
                shutil.rmtree(host_path)
                touch(host_path)
        else:
            touch(host_path)
        binds[host_path] = {'bind': container_path, 'ro': False}
    return binds


def start_rsyslog_container(ctx, extra_binds):
    image = ctx.image_name("rsyslog", "latest")
    command = ["rsyslogd", "-n"]
    hostname = "rsyslog"
    binds = get_common_binds(ctx, hostname)
    binds.update(extra_binds)
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 command=command, tty=True, binds=binds,
                                 network_name=ctx.network_name)
    ctx.state["containers"].append(container.short_id)
    container.start()
    log_started(hostname)
    ctx.state.fast_dump()
    return container


def start_server_container(ctx, command, extra_binds):
    image = ctx.image_name("server", "latest")
    hostname = "server"
    binds = get_common_binds(ctx, hostname)
    binds.update(extra_binds)
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 command=command, tty=True,
                                 binds=binds, privileged=False,
                                 network_name=ctx.network_name)
    ctx.state["containers"].append(container.short_id)
    container.start()
    log_started(hostname)
    ctx.state.fast_dump()
    return container


def start_frontend_container(ctx, command, extra_binds, port_bindings_offset, port_bindings_to_any):
    image = ctx.image_name("frontend", "latest")
    hostname = "frontend"
    binds = get_common_binds(ctx, hostname)
    binds.update(extra_binds)
    if "net_services" in ctx.state.manifest.keys():
        net_services = ctx.state.manifest["net_services"]
    elif "web_services" in ctx.state.manifest.keys():
        # try "web_services", for backward compatibility
        net_services = ctx.state.manifest["web_services"]
    else:
        raise Exception("Cannot find a net_service or web_service entry in the manifest.json file")
    ports = set([int(item[2]) for item in net_services if len(item) > 2])
    ports.add(80)
    port_bindings = {int(port): ("0.0.0.0" if port_bindings_to_any else "127.0.0.1", port_bindings_offset + int(port))
                     for port in ports}
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 volumes=["/home"], ports=list(ports),
                                 command=command, tty=True,
                                 binds=binds, privileged=False,
                                 port_bindings=port_bindings,
                                 network_name=ctx.network_name)
    ctx.state["containers"].append(container.short_id)
    container.start()
    log_started(hostname)
    ctx.state.fast_dump()
    return container


def start_nodes_containers(ctx, command, extra_binds, num_nodes, frontend):
    image = ctx.image_name("node", "latest")
    for i in range(1, num_nodes + 1):
        hostname = "node%d" % i
        binds = get_common_binds(ctx, "node")
        binds.update(extra_binds)
        container = Container.create(ctx.docker, image=image,
                                     detach=True, hostname=hostname,
                                     command=command, tty=True,
                                     binds=binds, privileged=False,
                                     volumes_from=[frontend.id],
                                     network_name=ctx.network_name)
        ctx.state["containers"].append(container.short_id)
        container.start()
        log_started(hostname)
        ctx.state.fast_dump()


def generate_cow_volumes_file(ctx, cow_volumes):
    with open(ctx.cow_volumes_file, "w") as fd:
        fd.write('\n'.join(cow_volumes) + '\n')


def generate_systemd_config_file(ctx, default_env={}):
    default_env_list = ['"%s=%s"' % (k, v) for k, v in iteritems(default_env)]
    default_config = """
# See systemd-system.conf(5) for details.
[Manager]
DefaultEnvironment="container=docker" %s
""" % (" ".join(default_env_list))
    with open(ctx.systemd_config_file, "w") as fd:
        fd.write(default_config)


def generate_etc_profile_file(ctx, default_env={}):
    etc_profile_vars = []
    for k, v in iteritems(default_env):
        etc_profile_vars.append("export %s=\"%s\"" % (k, v))
    with open(ctx.etc_profile_file, "w") as fd:
        fd.write('\n'.join(etc_profile_vars) + "\n")


def deploy(ctx, num_nodes, volumes, port_bindings_offset, port_bindings_to_any, needed_tag,
           parent_cmd, env={}):
    command = ["/usr/local/sbin/container-init"]
    nodes = ("frontend", "server", "node", "rsyslog")
    check_images_requirements(ctx, nodes, needed_tag, parent_cmd)

    init_scripts = op.join(ctx.envdir, "init-scripts")
    extra_binds = {
        init_scripts: {'bind': "/var/lib/container/init-scripts/", 'ro': True},
        ctx.cgroup_path: {'bind': "/sys/fs/cgroup", 'ro': True},
        ctx.nodes_file: {'bind': "/var/lib/container/nodes", 'ro': True},
        ctx.cow_volumes_file: {'bind': "/var/lib/container/cow_volumes",
                               'ro': True},
        ctx.systemd_config_file: {'bind': "/etc/systemd/system.d/oardocker.conf",
                                  'ro': True},
        ctx.etc_profile_file: {'bind': "/etc/profile.d/oardocker_env.sh",
                               'ro': True},
    }
    mount_options = ('ro', 'rw', 'cow')
    cow_volumes = []
    for volume in volumes:
        parts = volume.split(":")
        if len(parts) >= 3:
            host_path, container_path, mount_option = volume.split(":")
        elif len(parts) == 2:
            host_path, container_path = volume.split(":")
            mount_option = "rw"
        else:
            host_path = container_path = volume
            mount_option = "rw"

        if mount_option == "ro":
            ro = True
        elif mount_option == "rw":
            ro = False
        elif mount_option == "cow":
            ro = True
            cow_path = container_path
            container_path = "%s_read_only" % container_path
            cow_volumes.append("%s:%s" % (cow_path, container_path))
        else:
            raise ValueError("Volume '%s' have wrong option. Must be one the "
                             "following options %s" % (volume, mount_options))

        extra_binds[host_path] = {'bind': container_path, "ro": ro}

    ctx.docker.create_network()
    generate_cow_volumes_file(ctx, cow_volumes)
    generate_systemd_config_file(ctx, env)
    generate_etc_profile_file(ctx, env)

    start_rsyslog_container(ctx, extra_binds)
    frontend = start_frontend_container(ctx, command, extra_binds,
                                        port_bindings_offset, port_bindings_to_any)
    start_nodes_containers(ctx, command, extra_binds, num_nodes, frontend)
    start_server_container(ctx, command, extra_binds)
