import os
import click
from oardocker.cli import pass_context, pass_state, invoke_after_stop
from oardocker.actions import deploy


@click.command('start')
@click.option('-n', '--nodes', type=int, default=3, help="The cluster size")
@click.option('-v', '--volume', 'volumes', multiple=True,
              help="Bind mount a volume (e.g.: -v /host:/container)")
@click.option('-e', '--env', 'envs', multiple=True,
              help="Set environment variables")
@click.option('--x11', '--enable-x11', is_flag=True, default=False,
              help="Allowed containers to display x11 applications")
@click.option('--http-port', type=int, help="Server http port", default=48080)
@pass_state
@pass_context
@invoke_after_stop
def cli(ctx, state, nodes, volumes, envs, enable_x11, http_port):
    """Create and start the nodes"""
    env = {}
    volumes = list(volumes)
    for item in envs:
        key, value = item.strip().split("=")
        env[key] = value
    if enable_x11:
        env["DISPLAY"] = os.environ["DISPLAY"]
        volumes.append("/tmp/.X11-unix:/tmp/.X11-unix")
    deploy(ctx, state, nodes, volumes, http_port, "latest", "setup", env)
    ctx.log("\n%s\n" % ("*" * 72))
    ctx.log("API        : http://localhost:%s/oarapi/" % http_port)
    ctx.log("Monika     : http://localhost:%s/monika/" % http_port)
    ctx.log("Drawgantt  : http://localhost:%s/drawgantt-svg/" % http_port)
    ctx.log("PhpPgAdmin : http://localhost:%s/phppgadmin/" % http_port)
    ctx.log("\n%s\n" % ("*" * 72))
