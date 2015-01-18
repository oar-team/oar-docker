import click
from ..context import pass_context, on_started, on_finished


@click.command('restart')
@click.argument('hostnames', nargs=-1)
@click.option('-t', '--time', default=10,
              help="Number of seconds to try to stop for before killing the "
                   "container. Once killed it will then be restarted. "
                   "Default is 10 seconds")
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, hostnames, time):
    """Restart the containers"""
    restarted = click.style("Restarted", fg="green")
    cmd = ["restart", '-t', "%s" % time]
    for container in ctx.docker.get_containers():
        hostname = container.hostname
        args = cmd + [container.id]
        ctx.docker.cli(args)
        ctx.log("Container %s --> %s" % (hostname, restarted))
