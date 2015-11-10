# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import sys
from multiprocessing import Process, Queue

import click

from ..context import pass_context, on_started, on_finished
from ..compat import Empty, to_unicode


class LogPrinter(object):

    def __init__(self, container, lines, follow):
        self.container = container
        self.follow = follow
        self.lines = lines
        self.queue = Queue()
        self.prefix = self.container.get_log_prefix()
        self.process = None

    def run(self):
        if not self.follow:
            lines = self.container.logs(_iter=False,
                                        follow=self.follow,
                                        lines=self.lines).split('\n')
            text = '\n'.join(self.prefix + to_unicode(l) for l in lines)
            click.echo_via_pager(text)
        else:

            def feed():
                try:
                    for line in self.container.logs(_iter=True,
                                                    follow=self.follow,
                                                    lines=self.lines):
                        self.queue.put(self.prefix + to_unicode(line))
                except KeyboardInterrupt:
                    sys.exit(0)

            def join(terminate=False):
                if self.process is not None:
                    if not terminate:
                        if not self.process.is_alive():
                            self.process.join()
                    else:
                        if self.process.is_alive():
                            self.process.terminate()
                        self.process.join()

            self.process = Process(target=feed)
            self.process.start()

            try:
                while True:
                    try:
                        line = self.queue.get(timeout=0.2)
                        click.echo(line, nl=False)
                    except Empty:
                        join()
                    except KeyboardInterrupt:
                        sys.exit(0)
            finally:
                join(terminate=True)


@click.command('logs')
@click.argument('hostname', required=False, default="rsyslog")
@click.option('-n', '--lines', default=None,
              help="Number of journal entries to show")
@click.option('--no-tail', is_flag=True, default=False,
              help="Show all lines, even in follow mode")
@click.option('-f', '--follow', is_flag=True, default=False,
              help="Follow log output")
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, hostname, lines, no_tail, follow):
    """Fetch the logs of all nodes or only one."""
    containers = ctx.docker.get_containers_by_hosts()
    if hostname in containers:
        if no_tail:
            lines = "all"
        if lines is None:
            if follow:
                lines = 10
            else:
                lines = "all"
        LogPrinter(containers[hostname], lines, follow).run()
    else:
        raise click.ClickException("Cannot find the container with the "
                                   "name '%s'" % hostname)
