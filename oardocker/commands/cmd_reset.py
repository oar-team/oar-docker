import click
from oardocker.cli import pass_context, pass_state
from oardocker.actions import (generate_ssh_config, generate_empty_etc_hosts,
                               update_etc_hosts)


@click.command('reset')
@click.argument('hostnames', nargs=-1)
@pass_state
@pass_context
def cli(ctx, state, hostnames):
    """Restart the containers"""
    stopped = click.style("Stopped", fg="red")
    started = click.style("Started", fg="green")
    generate_empty_etc_hosts(ctx, state)
    for container in ctx.get_containers(state):
        name = container.name
        container.kill()
        container.stop()
        ctx.log("Container %s --> %s" % (name, stopped))
        container.start()
        update_etc_hosts(ctx, container)
        ctx.log("Container %s --> %s" % (name, started))
    generate_ssh_config(ctx, state)
