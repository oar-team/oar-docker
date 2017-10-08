# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import sys
import time
from multiprocessing import Process, Queue

import click
import docker

from ..context import pass_context, on_started
from ..compat import Empty, to_unicode


class LogPrinter(object):

    def __init__(self, ctx, hostname, lines, follow):
        self.ctx = ctx
        self.hostname = hostname
        self.follow = follow
        self.lines = lines
        self.STOP_FOLLOW = object()

    def get_container(self):
        try:
            self.ctx.state.load()
            containers = self.ctx.docker.get_containers_by_hosts()
            if self.hostname in containers:
                return containers[self.hostname]
        except docker.errors.NotFound:
            pass

    def run(self):
        def feed(container, queue):
            try:
                prefix = container.get_log_prefix()
                for line in container.logs(_iter=True,
                                           follow=self.follow,
                                           lines=self.lines):
                    queue.put(prefix + to_unicode(line))
            except KeyboardInterrupt:
                sys.exit(0)

        def print_all(container):
            prefix = container.get_log_prefix()
            lines = container.logs(_iter=False,
                                   follow=self.follow,
                                   lines=self.lines).split('\n')
            text = '\n'.join(prefix + to_unicode(l) for l in lines)
            click.echo_via_pager(text.strip('\n'))

        def print_follow(container):
            queue = Queue()
            process = Process(target=feed, args=(container, queue))
            process.start()

            try:
                while True:
                    try:
                        line = queue.get(timeout=0.2)
                        click.echo(line, nl=False)
                    except Empty:
                        if not process.is_alive():
                            process.join()
                            break
                    except KeyboardInterrupt:
                        return self.STOP_FOLLOW
            finally:
                if process.is_alive():
                    process.terminate()
                process.join()

        if not self.follow:
            container = self.get_container()
            if container is not None:
                print_all(container)
        else:
            while True:
                container = self.get_container()
                if container is None:
                    time.sleep(0.2)
                else:
                    rev = print_follow(container)
                    if rev is self.STOP_FOLLOW:
                        break
                self.lines = "all"
            click.echo()


@click.command('logs')
@click.option('-n', '--lines', default=None,
              help="Number of journal entries to show")
@click.option('--no-tail', is_flag=True, default=False,
              help="Show all lines, even in follow mode")
@click.option('-f', '--follow', is_flag=True, default=False,
              help="Follow log output")
@pass_context
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, lines, no_tail, follow):
    """Fetch the logs of all nodes or only one."""
    if no_tail:
        lines = "all"
    if lines is None:
        if follow:
            lines = 10
        else:
            lines = "all"
    LogPrinter(ctx, "rsyslog", lines, follow).run()
