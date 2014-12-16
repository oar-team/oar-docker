import os
import os.path as op
import click
from oardocker.utils import check_tarball, check_git, check_url, \
    download_file, git_pull_or_clone, touch, append_file, empty_file
from oardocker.container import Container


def execute(ctx, state, user, hostname, cmd, workdir):
    node_name = ''.join([i for i in hostname if not i.isdigit()])
    nodes = ("frontend", "services", "node", "server")
    if not node_name in nodes:
        raise click.ClickException("Cannot find the container with the name "
                                   "'%s'" % hostname)
    containers = dict((c.hostname, c) for c in ctx.get_containers(state))
    if not hostname in containers.keys():
        raise click.ClickException("The container must be started before "
                                   "running this command. Run  `oardocker"
                                   " start` first")
    user_cmd = ' '.join(cmd)
    return ctx.docker_cli("exec", "-it", containers[hostname].id,
                          "script", "-q", "/dev/null", "-c",
                          "exec setuser %s /bin/bash -ilc 'cd %s && %s'" %
                          (user, workdir, user_cmd))


def check_images_requirements(ctx, state, nodes, needed_tag, parent_cmd):
    available_images = [', '.join(im["RepoTags"]) for im in
                        ctx.get_images(state)]
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


def install(ctx, state, src, needed_tag, tag, parent_cmd):
    nodes = ("frontend", "server", "node")
    # check_images_requirements(ctx, state, nodes, needed_tag, parent_cmd)
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
    for node in nodes:
        image = ctx.image_name(node, needed_tag)
        container = Container.create(ctx.docker, image=image, command=command)
        state["containers"].append(container.short_id)
        exit_code = container.start_and_attach(binds=binds, privileged=True)
        if exit_code:
            msg = "Container %s exited with code %s\n" % (container.id,
                                                          exit_code)
            raise click.ClickException(msg)
        oar_version = container.logs().strip().split('\n')[-1]
        repository = ctx.image_name(node)
        commit = container.commit(repository=repository, tag=tag,
                                  message=oar_version)
        ctx.save_image(commit['Id'], tag=tag, repository=repository)
        state["images"].append(commit['Id'])
        container.remove(v=False, link=False, force=True)


def log_started(hostname):
    started = click.style("Started", fg="green")
    click.echo("Container %s --> %s" % (hostname, started))


def start_server_container(ctx, state, command, extra_binds, num_nodes, env):
    image = ctx.image_name("server", "latest")
    hostname = "server"
    binds = {}
    binds.update(extra_binds)
    environment = dict(env)
    environment["NUM_NODES"] = num_nodes
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 environment=env, ports=[22],
                                 command=command, tty=True)
    state["containers"].append(container.short_id)
    container.start(binds=binds, privileged=True,
                    volumes_from=None)
    log_started(hostname)
    update_etc_hosts(ctx, container)
    return container


def start_frontend_container(ctx, state, command, extra_binds, num_nodes,
                             http_port, env):
    image = ctx.image_name("frontend", "latest")
    hostname = "frontend"
    binds = {}
    binds.update(extra_binds)
    environment = dict(env)
    environment["NUM_NODES"] = num_nodes
    container = Container.create(ctx.docker, image=image,
                                 detach=True, hostname=hostname,
                                 environment=environment, volumes=["/home"],
                                 ports=[22, 80], command=command, tty=True)
    state["containers"].append(container.short_id)
    container.start(binds=binds, privileged=True,
                    port_bindings={80: ('127.0.0.1', http_port)},
                    volumes_from=None)
    log_started(hostname)
    update_etc_hosts(ctx, container)
    return container


def start_nodes_containers(ctx, state, command, extra_binds, num_nodes,
                           frontend, env):
    image = ctx.image_name("node", "latest")
    for i in xrange(1, num_nodes + 1):
        hostname = "node%d" % i
        binds = {}
        binds.update(extra_binds)
        container = Container.create(ctx.docker, image=image,
                                     detach=True, hostname=hostname,
                                     ports=[22], command=command, tty=True,
                                     environment=env)
        state["containers"].append(container.short_id)
        container.start(binds=binds, privileged=True,
                        volumes_from=frontend.id)
        log_started(hostname)
        update_etc_hosts(ctx, container)


def deploy(ctx, state, num_nodes, volumes, http_port, needed_tag, parent_cmd,
           env={}):
    generate_ssh_config(ctx, state)
    command = ["/usr/local/sbin/oardocker_init"]
    nodes = ("frontend", "server", "node")
    check_images_requirements(ctx, state, nodes, needed_tag, parent_cmd)

    my_initd = op.join(ctx.envdir, "my_init.d")
    extra_binds = {
        my_initd: {'bind': "/var/lib/container/my_init.d/", 'ro': True},
        ctx.dnsfile: {'bind': "/etc/hosts", 'ro': True},
        ctx.cgroup_path: {'bind': "/sys/fs/cgroup", 'ro': True}
    }
    for volume in volumes:
        host_path, container_path = volume.split(":")
        extra_binds[host_path] = {'bind': container_path, "ro": False}
    start_server_container(ctx, state, command, extra_binds, num_nodes, env)
    frontend = start_frontend_container(ctx, state, command, extra_binds,
                                        num_nodes, http_port, env)
    start_nodes_containers(ctx, state, command, extra_binds,
                           num_nodes, frontend, env)
    generate_ssh_config(ctx, state)


def generate_ssh_config(ctx, state):
    touch(ctx.ssh_config)
    entry = """
Host {}
  HostName {}
"""
    default = """Host *
  User docker
  IdentityFile {}
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentitiesOnly yes
  LogLevel FATAL
  ForwardAgent yes
  Compression yes
  Protocol 2
""".format(ctx.ssh_key)
    key_sort = lambda c: c.dictionary["NetworkSettings"]["IPAddress"]
    with open(ctx.ssh_config, "w") as ssh_config:
        ssh_config.write(default)
        for c in sorted(ctx.get_containers(state), key=key_sort):
            ipaddress = c.dictionary["NetworkSettings"]["IPAddress"]
            hostname = c.dictionary["Config"]["Hostname"]
            if ipaddress:
                ssh_config.write(entry.format(hostname, ipaddress))


def generate_empty_etc_hosts(ctx, state):
    empty_file(ctx.dnsfile)
    default_etc_hosts = """fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.0.1   localhost
::1 localhost ip6-localhost ip6-loopback
"""
    append_file(ctx.dnsfile, default_etc_hosts)


def update_etc_hosts(ctx, container):
    container.inspect()
    ipaddress = container.dictionary["NetworkSettings"]["IPAddress"]
    hostname = container.dictionary["Config"]["Hostname"]
    if ipaddress:
        append_file(ctx.dnsfile, "%s %s\n" % (ipaddress, hostname))
