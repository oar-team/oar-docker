import click
from oardocker.cli import pass_context, pass_state


@click.command('connect')
@click.argument('hostname', required=False, default="frontend")
@click.option('-l', 'user', default="docker")
@pass_state
@pass_context
def cli(ctx, state, hostname, user):
    """Connect to a node."""
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
    ctx.docker_cli("exec", "-it", containers[hostname].id,
                   "script", "-q", "/dev/null", "-c",
                   "cat /etc/motd && exec setuser %s /bin/bash -il" % user)
