import os
import os.path as op
import sys
import click
import docker
from functools import update_wrapper
from oarcluster.utils import copy_tree


HERE = op.dirname(__file__)
CONTEXT_SETTINGS = dict(auto_envvar_prefix='OARCLUSTER')


class Context(object):

    @property
    def oar_version_file(self):
        return op.join(self.workdir, "version-%s.txt" % self.oar_version)

    def __init__(self):
        self.version = '0.1'
        self.state = {"images": [], "containers": []}
        self._docker_client = None
        self.prefix = "oarcluster"
        self.current_dir = os.getcwd()
        self.workdir = self.current_dir
        self.templates_dir = op.abspath(op.join(HERE, 'templates'))
        self.docker_host = None
        self.volumes = []
        self.num_nodes = 3
        self.connect_ssh = False
        self.enable_colmet = False
        # oar archive url
        self.oar_version = "unknown"
        self.oar_website = "http://oar-ftp.imag.fr/oar"
        self.oar_tarball = "%s/2.5/sources/stable/oar-2.5.3.tar.gz" \
                           % self.oar_website

    def update(self):
        self.envdir = op.join(self.workdir, ".%s" % self.prefix)
        self.ssh_config = op.join(self.envdir, "ssh_config")
        self.ssh_key = op.join(self.envdir, "ssh_insecure_key")
        self.dnsfile = op.join(self.envdir, "dnsmasq.d", "hosts")
        self.postinstall_dir = op.join(self.envdir, "postinstall")

    def assert_valid_env(self):
        if not os.path.isdir(self.envdir):
            raise click.ClickException("Missing oarcluster env directory."
                                       " Run `oarcluster init` to create"
                                       " a new oarcluster environment")

    def copy_tree(self, src, dest, overwrite=False):
        if os.path.exists(dest) and not overwrite:
            raise click.ClickException("File exists : '%s'" % dest)
        copy_tree(src, dest)

    def log(self, msg, *args):
        """Logs a message to stderr."""
        if args:
            msg %= args
        click.echo(msg, file=sys.stderr)

    def vlog(self, msg, *args):
        """Logs a message to stderr only if verbose is enabled."""
        if self.verbose:
            self.log(msg, *args)

    def save_state(self):
        if self.state:
            print("save state")

    @property
    def docker(self):
        if self._docker_client is None:
            self._docker_client = docker.Client(base_url=self.docker_host,
                                                timeout=10)
        return self._docker_client


pass_context = click.make_pass_decorator(Context, ensure=True)
cmd_folder = op.abspath(op.join(HERE, 'commands'))


class OARClusterCLI(click.MultiCommand):

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
        try:
            mod = __import__('oarcluster.commands.cmd_' + name,
                             None, None, ['cli'])
        except ImportError:
            raise
            return
        return mod.cli


def handle_exception(f):
    @click.pass_context
    def new_func(ctx, *args, **kwargs):
        try:
            return ctx.invoke(f, *args, **kwargs)
        except click.ClickException:
            raise
        except Exception as e:
            raise click.ClickException("%s" % e)
        finally:
            cmds = ["build", "destroy", "install", "start", "stop"]
            if ctx.command.name in cmds:
                ctx.obj.save_state()

    return update_wrapper(new_func, f)


@click.command(cls=OARClusterCLI, context_settings=CONTEXT_SETTINGS)
@click.option('--workdir', type=click.Path(exists=True, file_okay=False,
                                           resolve_path=True),
              help='Changes the folder to operate on.')
@click.option('--docker-host', default="unix://var/run/docker.sock")
@pass_context
def cli(ctx, workdir, docker_host):
    """Manage a small OAR developpement cluster with docker."""
    if workdir is not None:
        ctx.workdir = workdir
    if docker_host is not None:
        ctx.docker_host = docker_host
    ctx.update()


def main(*arg, **kwargs):
    try:
        cli(*arg, **kwargs)
    except Exception as e:
        sys.stderr.write("\nError: %s\n" % e)
        sys.exit(1)
