import click
import arrow
from oarcluster.cli import pass_context, pass_state
from tabulate import tabulate
from oarcluster.utils import human_filesize


def get_containers_table(ctx, state):
    containers = ctx.get_containers(state)
    rows = []
    for c in containers:
        image_name = c.dictionary['Config']['Image']
        created = arrow.get(c.dictionary['Created']).humanize()
        if c.is_running:
            color = "green"
        else:
            color = "red"
        ip = c.dictionary["NetworkSettings"]["IPAddress"]
        rows.append([c.name, c.short_id, image_name, c.human_readable_command,
                    created, click.style(c.human_readable_state, fg=color),
                    ip, c.human_readable_ports])
    if not rows:
        rows.append(["", "", "", "", "", "", "", ""])
    return rows, ["Containers", "ID", "Image", "Command", "Created", "Status",
                  "IP", "Ports"]


def get_images_table(ctx, state):
    images = ctx.get_images(state)
    rows = []
    for im in images:
        name = im["RepoTags"][0]
        comment = ctx.docker.inspect_image(im["Id"])["Comment"]
        imgid = im["Id"][:12]
        created = arrow.get(im['Created']).humanize()
        virtsize = im["VirtualSize"]
        rows.append([name, imgid, created, human_filesize(virtsize), comment])
    if not rows:
        rows.append(["", "", "", "", ""])
    return rows, ["Images", "ID", "Created", "Virtual Size", "Comment"]


@click.command('status')
@pass_state
@pass_context
def cli(ctx, state):
    """Output status of the cluster"""
    images_table, images_headers = get_images_table(ctx, state)
    click.echo(tabulate(images_table, headers=images_headers))
    click.echo("")
    c_table, c_headers = get_containers_table(ctx, state)
    click.echo(tabulate(c_table, headers=c_headers))
