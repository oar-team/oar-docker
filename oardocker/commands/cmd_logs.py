# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import sys
from multiprocessing import Process, Queue

import click

from ..context import pass_context, on_started, on_finished
from ..compat import Empty, to_unicode


class LogPrinter(object):

    def __init__(self, containers, tail, follow):
        self.containers = containers
        self.follow = follow
        self.tail = tail
        self.prefix_width = self.compute_prefix_width(containers)
        self.queue = Queue()
        self.processes = []

    def compute_prefix_width(self, containers):
        prefix_width = 0
        for container in containers:
            prefix_width = max(prefix_width, len(container.hostname))
        return prefix_width

    def feed_queue(self, container):
        try:
            prefix = container.get_log_prefix(self.prefix_width)
            for line in container.logs(_iter=True,
                                       follow=self.follow,
                                       tail=self.tail):
                self.queue.put(prefix + to_unicode(line))
        except KeyboardInterrupt:
            sys.exit(0)

    def run(self):
        for container in self.containers:
            p = Process(target=self.feed_queue, args=(container,))
            p.start()
            self.processes.append(p)

        def join_processes(terminate=False):
            alive_processes = []
            for process in self.processes:
                if not terminate:
                    if not process.is_alive():
                        process.join()
                    else:
                        alive_processes.append(process)
                    self.processes = alive_processes[:]
                else:
                    if process.is_alive():
                        process.terminate()
                    process.join()

        try:
            while True:
                try:
                    line = self.queue.get(timeout=0.2)
                    click.echo(line, nl=False)
                except Empty:
                    if len(self.processes) == 0:
                        break
                    join_processes()
                except KeyboardInterrupt:
                    sys.exit(0)
        finally:
            join_processes(terminate=True)


@click.command('logs')
@click.argument('hostname', required=False, default="")
@click.option('-t', '--tail', default=-1,
              help="Output the specified number of lines at the end of logs")
@click.option('-f', '--follow', is_flag=True, default=False,
              help="Follow log output")
@pass_context
@on_finished(lambda ctx: ctx.state.dump())
@on_started(lambda ctx: ctx.assert_valid_env())
def cli(ctx, hostname, tail, follow):
    """Fetch the logs of all nodes or only one."""
    containers = list(ctx.docker.get_containers())
    if hostname:
        node_name = ''.join([i for i in hostname if not i.isdigit()])
        nodes = ("frontend", "services", "node", "server")
        if node_name not in nodes:
            raise click.ClickException("Cannot find the container with the "
                                       "name '%s'" % hostname)
        containers = [c for c in containers if hostname in c.hostname]
    if not containers:
        print_msg = "container" if hostname else "containers"
        raise click.ClickException("The %s must be started before "
                                   "running this command. Run  `oardocker"
                                   " start` first" % print_msg)
    else:
        LogPrinter(containers, tail, follow).run()
