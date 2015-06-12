# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import os.path as op
import shutil
import sys

from .compat import iteritems, reraise
from .container import Container
from .utils import (check_tarball, check_git, check_url, download_file,
                    git_pull_or_clone, touch)

import click


def execute(ctx, user, hostname, cmd, workdir):
    node_name = ''.join([i for i in hostname if not i.isdigit()])
    nodes = ("frontend", "services", "node", "server")
    if node_name not in nodes:
        raise click.ClickException("Cannot find the container with the name "
                                   "'%s'" % hostname)
    containers = dict((c.hostname, c) for c in ctx.docker.get_containers())
    if hostname not in containers.keys():
        raise click.ClickException("The container must be started before "
                                   "running this command. Run  `oardocker"
                                   " start` first")
    user_cmd = ' '.join(cmd)
    return containers[hostname].execute(user_cmd, user, workdir)


def check_images_requirements(ctx, nodes, needed_tag, parent_cmd):
    available_images = [', '.join(im["RepoTags"]) for im in
                        ctx.docker.get_images()]
    no_missings_images = set()
    needed_images = set([ctx.image_name(node, needed_tag) for node in nodes])
    for image in needed_images:
        for available_image in available_images:
            if image in available_image:
                no_missings_images.add(image)
    missings_images = list(set(needed_images) - set(no_missings_images))
    if missings_images:
        for image in missings_images:
            image_name = click.style(image, fg="red")
            click.echo("missing image '%s'" % image_name)
        raise click.ClickException("You need build base images first with "
                                   "`%s` command" % parent_cmd)


def install(ctx, src, needed_tag, tag, parent_cmd):
    nodes = ("frontend", "server", "node")
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
        ctx.log('Fetching OAR src from %s...' % src)
        if is_git:
            path = op.join(ctx.postinstall_dir, "oar-git")
            git_pull_or_clone(src, path)
        else:
            path = op.join(ctx.postinstall_dir, "oar-tarball.tar.gz")
            download_file(src, path)
    else:
        path = src
    ctx.log('Installing OAR from %s' % src)
    postinstall_cpath = "/tmp/postintall"
    if is_git:
        src_cpath = "%s/oar-git" % postinstall_cpath
    else:
        src_cpath = "%s/tarballs/oar-tarball.tar.gz" % postinstall_cpath
    binds = {path: {'bind': src_cpath, 'ro': True}}
    command = ["/root/install_oar.sh", src_cpath]
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
        cli_options = ["run", "-a", "STDOUT", "-a", "STDERR",
                       "--privileged", "--name", container_name]
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
        '/root/.bash_hisotry',
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


def start_server_container(ctx, command, extra_binds, num_nodes, env):
    image = ctx.image_name("server", "latest")
    hostname = "server"
    binds = get_common_binds(ctx, hostname)
    binds.update(extra_binds)
    environment = dict(env)
    environment["NUM_NODES"] = num_nodes
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 environment=environment, ports=[22],
                                 command=command, tty=True)
    ctx.state["containers"].append(container.short_id)
    container.start(binds=binds, privileged=True,
                    volumes_from=None)
    log_started(hostname)
    ctx.state.update_etc_hosts(container)
    return container


def start_frontend_container(ctx, command, extra_binds, num_nodes,
                             http_port, env):
    image = ctx.image_name("frontend", "latest")
    hostname = "frontend"
    binds = get_common_binds(ctx, hostname)
    binds.update(extra_binds)
    environment = dict(env)
    environment["NUM_NODES"] = num_nodes
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 environment=environment, volumes=["/home"],
                                 ports=[22, 80], command=command, tty=True)
    ctx.state["containers"].append(container.short_id)
    container.start(binds=binds, privileged=True,
                    port_bindings={80: ('127.0.0.1', http_port)},
                    volumes_from=None)
    log_started(hostname)
    ctx.state.update_etc_hosts(container)
    return container


def start_nodes_containers(ctx, command, extra_binds, num_nodes,
                           frontend, env):
    image = ctx.image_name("node", "latest")
    environment = dict(env)
    environment["NUM_NODES"] = num_nodes
    for i in range(1, num_nodes + 1):
        hostname = "node%d" % i
        binds = get_common_binds(ctx, "node")
        binds.update(extra_binds)
        container = Container.create(ctx.docker, image=image,
                                     detach=True, hostname=hostname,
                                     ports=[22], command=command, tty=True,
                                     environment=environment)
        ctx.state["containers"].append(container.short_id)
        container.start(binds=binds, privileged=True,
                        volumes_from=frontend.id)
        log_started(hostname)
        ctx.state.update_etc_hosts(container)


def deploy(ctx, num_nodes, volumes, http_port, needed_tag, parent_cmd,
           env={}):
    command = ["/usr/local/sbin/oardocker_init"]
    nodes = ("frontend", "server", "node")
    check_images_requirements(ctx, nodes, needed_tag, parent_cmd)

    my_initd = op.join(ctx.envdir, "my_init.d")
    extra_binds = {
        my_initd: {'bind': "/var/lib/container/my_init.d/", 'ro': True},
        ctx.dns_file: {'bind': "/etc/hosts", 'ro': True},
        ctx.cgroup_path: {'bind': "/sys/fs/cgroup", 'ro': True},
        ctx.nodes_file: {'bind': "/var/lib/container/nodes", 'ro': True}
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
    env['COW_VOLUMES'] = '\n'.join(cow_volumes)
    frontend = start_frontend_container(ctx, command, extra_binds,
                                        num_nodes, http_port, env)
    start_nodes_containers(ctx, command, extra_binds, num_nodes, frontend, env)
    start_server_container(ctx, command, extra_binds, num_nodes, env)
