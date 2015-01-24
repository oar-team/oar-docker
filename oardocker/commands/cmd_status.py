# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
import arrow
from ..context import pass_context, on_started, on_finished
from tabulate import tabulate
from ..utils import human_filesize


def get_containers_table(ctx):
    containers = ctx.docker.get_containers()
    rows = []
    for c in containers:
        created = arrow.get(c.dictionary['Created']).humanize()
        if c.is_running:
            status = click.style(c.human_readable_state, fg="green")
        else:
            status = click.style(c.human_readable_state, fg="red")
        rows.append([c.hostname, c.ip, status, c.human_readable_ports,
                    c.short_id, c.image_name, created])
    if not rows:
        rows.append(["", "", "", "", "", "", ""])
    return rows, ["Containers", "IP", "Status", "Ports", "ID", "Image",
                  "Created"]


def get_images_table(ctx):
    images = ctx.docker.get_images()
    rows = []
    for im in images:
        name = im["RepoTags"][0]
        comment = ctx.docker.api.inspect_image(im["Id"])["Comment"]
        imgid = im["Id"][:12]
        created = arrow.get(im['Created']).humanize()
        virtsize = im["VirtualSize"]
        rows.append([name, imgid, created, human_filesize(virtsize), comment])
    if not rows:
        rows.append(["", "", "", "", ""])
    return rows, ["Images", "ID", "Created", "Virtual Size", "Comment"]


@click.command('status')
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx):
    """Output status of the cluster"""
    images_table, images_headers = get_images_table(ctx)
    click.echo(tabulate(images_table, headers=images_headers))
    click.echo("")
    c_table, c_headers = get_containers_table(ctx)
    click.echo(tabulate(c_table, headers=c_headers))
