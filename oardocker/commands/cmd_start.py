import click
from oardocker.cli import pass_context, pass_state, invoke_after_stop
from oardocker.actions import deploy


@click.command('start')
@click.option('-n', '--nodes', type=int, default=3, help="The cluster size")
@click.option('-v', '--volume', 'volumes', multiple=True,
              help="Bind mount a volume (e.g.: -v /host:/container)")
@click.option('--http-port', type=int, help="Server http port", default=48080)
@pass_state
@pass_context
@invoke_after_stop
def cli(ctx, state, nodes, volumes, http_port):
    """Start the cluster"""
    deploy(ctx, state, nodes, volumes, http_port, "latest", "setup")
    ctx.log("\n%s\n" % ("*" * 72))
    ctx.log("API        : http://localhost:%s/oarapi/" % http_port)
    ctx.log("Monika     : http://localhost:%s/monika" % http_port)
    ctx.log("Drawgantt  : http://localhost:%s/drawgantt-svg" % http_port)
    ctx.log("PhpPgAdmin : http://localhost:%s/phppgadmin" % http_port)
    ctx.log("\n%s\n" % ("*" * 72))