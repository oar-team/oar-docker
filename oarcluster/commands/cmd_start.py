import click
from oarcluster.cli import pass_context, pass_state, invoke_after_stop
from oarcluster.actions import deploy


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
