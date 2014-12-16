import os
import os.path as op
import sys
import click
import docker
import json
from functools import update_wrapper
from oardocker.utils import copy_tree, find_executable
from oardocker.container import Container
from sh import chmod
from subprocess import call
from oardocker import VERSION


HERE = op.dirname(__file__)
TEMPLATES_PATH = op.abspath(op.join(HERE, 'templates'))
VARIANTS = os.listdir(TEMPLATES_PATH)
CONTEXT_SETTINGS = dict(auto_envvar_prefix='oardocker',
                        help_option_names=['-h', '--help'])


class Context(object):

    def __init__(self):
        self.version = VERSION
        self._docker_client = None
        self.current_dir = os.getcwd()
        self.workdir = self.current_dir
        self.docker_host = None
        self.cgroup_path = None
        # oar archive url
        self.oar_website = "http://oar-ftp.imag.fr/oar/2.5/sources/stable"
        self.oar_tarball = "%s/oar-2.5.3.tar.gz" % self.oar_website
        self.docker_exe = None
        self.prefix = "oardocker"

    def docker_cli(self, *call_args):
        if self.docker_exe is None:
            raise click.ClickException("Cannot find docker executable in your"
                                       " PATH")
        args = list(call_args)
        args.insert(0, self.docker_exe)
        call(args)

    @property
    def env(self):
        with open(self.env_file) as env_file:
            return env_file.read().strip()

    def image_name(self, node, tag=""):
        if not tag == "":
            tag = ":%s" % tag
        if not self.env == "default":
            return "%s/%s-%s%s" % (self.prefix, self.env, node, tag)
        else:
            return "%s/%s%s" % (self.prefix, node, tag)


    def update(self):
        self.envdir = op.join(self.workdir, ".%s" % self.prefix)
        self.ssh_key = op.join(self.envdir, "images", "base", "skel", ".ssh",
                               "id_rsa")
        self.ssh_config = op.join(self.envdir, "ssh_config")
        self.dnsfile = op.join(self.envdir, "dnsmasq.d", "hosts")
        self.postinstall_dir = op.join(self.envdir, "postinstall")
        self.env_file = op.join(self.envdir, "env")
        self.state_file = op.join(self.envdir, "state.json")
        self.docker_exe = find_executable(self.docker_binary)

    def assert_valid_env(self):
        if not os.path.isdir(self.envdir):
            raise click.ClickException("Missing oardocker env directory."
                                       " Run `oardocker init` to create"
                                       " a new oardocker environment")

    def copy_tree(self, src, dest, overwrite=False):
        if os.path.exists(dest) and not overwrite:
            raise click.ClickException("File exists : '%s'" % dest)
        copy_tree(src, dest)
        chmod("600", self.ssh_key)

    def log(self, msg, *args):
        """Logs a message to stderr."""
        if args:
            msg %= args
        click.echo(msg, file=sys.stderr)

    def vlog(self, msg, *args):
        """Logs a message to stderr only if verbose is enabled."""
        if self.verbose:
            self.log(msg, *args)

    def save_state(self, state):
        if op.isdir(op.dirname(self.state_file)):
            with open(self.state_file, "w+") as json_file:
                state["images"] = list(set(state["images"]))
                state["containers"] = list(set(state["containers"]))
                json_file.write(json.dumps(state))

    def load_state(self):
        state = {"images": [], "containers": []}
        if op.isfile(self.state_file):
            try:
                with open(self.state_file) as json_file:
                    state = json.loads(json_file.read())
                    images = set([im[:12] for im in state["images"]])
                    state["images"] = list(images)
                    containers = set([c[:12] for c in state["containers"]])
                    state["containers"] = list(containers)
            except:
                pass
        return state

    def get_containers(self, state):
        containers = self.docker.containers(quiet=False, all=True, trunc=False,
                                            latest=False)
        for container in containers:
            if not container["Id"][:12] in state["containers"]:
                continue
            yield Container.from_id(self.docker, container["Id"])

    def get_containers_ids(self, state):
        for container in self.get_containers(state):
            yield container.short_id

    def get_images_ids(self, state):
        for image in self.get_images(state):
            yield image["Id"][:12]

    def get_images(self, state):
        images = self.docker.images(name=None, quiet=False,
                                    all=False, viz=False)
        for image in images:
            if not image["Id"][:12] in state["images"]:
                continue
            yield image

    def remove_image(self, image, force=True):
        image_name = ', '.join(image["RepoTags"])
        image_id = image["Id"]
        self.docker.remove_image(image_id, force=force)
        removed = click.style("Removed", fg="blue")
        self.log("Image %s (%s) --> %s" % (image_id, image_name, removed))

    def save_image(self, image_id, repository, tag):
        saved = click.style("Saved", fg="green")
        image_name = "%s:%s" % (repository, tag)
        self.docker.tag(image_id, repository=repository, tag=tag, force=True)
        self.log("Image %s (%s) --> %s" % (image_id, image_name, saved))

    @property
    def docker(self):
        if self._docker_client is None:
            self._docker_client = docker.Client(base_url=self.docker_host,
                                                timeout=10)
        return self._docker_client


pass_context = click.make_pass_decorator(Context, ensure=True)
cmd_folder = op.abspath(op.join(HERE, 'commands'))


class oardockerCLI(click.MultiCommand):

    def list_commands(self, ctx):
        commands = []
        for filename in os.listdir(cmd_folder):
            if filename.endswith('.py') and filename.startswith('cmd_'):
                commands.append(filename[4:-3])
        commands.sort()
        return commands

    def get_command(self, ctx, name):
        if sys.version_info[0] == 2:
            name = name.encode('ascii', 'replace')
        if name in self.list_commands(ctx):
            mod = __import__('oardocker.commands.cmd_' + name,
                             None, None, ['cli'])
            return mod.cli


def pass_state(f):
    @click.pass_context
    def new_func(ctx, *args, **kwargs):
        ctx.obj.assert_valid_env()
        state = ctx.obj.load_state()
        state["containers"] = list(ctx.obj.get_containers_ids(state))
        state["images"] = list(ctx.obj.get_images_ids(state))
        try:
            return ctx.invoke(f, state, *args, **kwargs)
        finally:
            ctx.obj.save_state(state)

    return update_wrapper(new_func, f)


def invoke_after_stop(f):
    @click.pass_context
    def new_func(ctx, *args, **kwargs):
        stop_cmd = ctx.parent.command.get_command(ctx, "stop")
        ctx.invoke(stop_cmd)
        return ctx.invoke(f, *args, **kwargs)

    return update_wrapper(new_func, f)


def invoke_before_clean(f):
    @click.pass_context
    def new_func(ctx, *args, **kwargs):
        try:
            return ctx.invoke(f, *args, **kwargs)
        finally:
            clean_cmd = ctx.parent.command.get_command(ctx, "clean")
            click.echo("Cleanup...")
            ctx.invoke(clean_cmd)

    return update_wrapper(new_func, f)



class deprecated_cmd(object):
    """This is a decorator which can be used to mark cmd as deprecated. It will
    result in a warning being emmitted when the command is invoked."""

    def __init__(self, message=""):
        if message:
            self.message = "%s." % message
        else:
            self.message = message

    def __call__(self, f):

        @click.pass_context
        def new_func(ctx, *args, **kwargs):
            msg = click.style("warning: `%s` command is deprecated. %s" %
                              (ctx.info_name, self.message), fg="yellow")
            click.echo(msg)
            return ctx.invoke(f, *args, **kwargs)

        return update_wrapper(new_func, f)

@click.command(cls=oardockerCLI, context_settings=CONTEXT_SETTINGS, chain=True)
@click.option('--workdir', type=click.Path(exists=True, file_okay=False,
                                           resolve_path=True),
              help='Changes the folder to operate on.')
@click.option('--docker-host', default="unix://var/run/docker.sock",
              help="The docker socket [default: unix://var/run/docker.sock]")
@click.option('--cgroup-path', default="/sys/fs/cgroup",
              help="The cgroup file system path [default: /sys/fs/cgroup]")
@click.option('--docker-binary', default="docker",
              help="The docker client binary [default: docker]")
@click.version_option()
@pass_context
def cli(ctx, workdir, docker_host, cgroup_path, docker_binary):
    """Manage a small OAR developpement cluster with docker."""
    if workdir is not None:
        ctx.workdir = workdir
    ctx.docker_host = docker_host
    ctx.cgroup_path = cgroup_path
    ctx.docker_binary = docker_binary
    ctx.update()


def main(args=sys.argv[1:]):
    try:
        cli(args)
    except Exception as e:
        sys.stderr.write(u"\nError: %s\n" % e)
        sys.exit(1)
