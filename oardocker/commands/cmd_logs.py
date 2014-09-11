from __future__ import unicode_literals

from Queue import Queue, Empty
from threading import Thread

import time
import click
from oardocker.cli import pass_context, pass_state


def split_buffer(reader, separator):
    """
    Given a generator which yields strings and a separator string,
    joins all input, splits on the separator and yields each chunk.

    Unlike string.split(), each chunk includes the trailing
    separator, except for the last one if none was found on the end
    of the input.
    """
    buffered = str('')
    separator = str(separator)

    for data in reader:
        buffered += data
        while True:
            index = buffered.find(separator)
            if index == -1:
                break
            yield buffered[:index + 1]
            buffered = buffered[index + 1:]

    if len(buffered) > 0:
        yield buffered

# Yield STOP from an input generator to stop the
# top-level loop without processing any more input.
STOP = object()


class Multiplexer(object):
    def __init__(self, generators):
        self.generators = generators
        self.queue = Queue()

    def loop(self, callback):
        def loop_target(callback):
            while True:
                try:
                    item = self.queue.get(timeout=0.1)
                    if item is STOP:
                        break
                    else:
                        callback(item)
                except Empty:
                    pass

        def _enqueue_output(generator):
            for item in generator:
                self.queue.put(item)

        loop_thread = Thread(target=loop_target, args=(callback,))
        loop_thread.daemon = True
        loop_thread.start()
        for generator in self.generators:
            t = Thread(target=_enqueue_output, args=(generator,))
            t.daemon = True
            t.start()
            time.sleep(0.1)
        while loop_thread.is_alive():
            loop_thread.join(1)


class LogPrinter(object):
    def __init__(self, containers):
        self.containers = containers
        self.prefix_width = self._calculate_prefix_width(containers)
        self.generators = self._make_log_generators()

    def run(self):
        mux = Multiplexer(self.generators)
        mux.loop(callback=lambda x: click.echo(x, nl=False))

    def _calculate_prefix_width(self, containers):
        """
        Calculate the maximum width of container names so we can make the log
        prefixes line up like so:

        db_1  | Listening
        web_1 | Listening
        """
        prefix_width = 0
        for container in containers:
            prefix_width = max(prefix_width, len(container.hostname))
        return prefix_width

    def _make_log_generators(self):
        generators = []

        for container in self.containers:
            generators.append(self._make_log_generator(container))

        return generators

    def _make_log_generator(self, container):
        prefix = self._generate_prefix(container).encode('utf-8')
        # Attach to container before log printer starts running
        line_generator = split_buffer(self._attach(container), '\n')
        for line in line_generator:
            yield prefix + line
        exit_code = container.wait()
        yield "%s exited with code %s\n" % (container.name, exit_code)
        yield STOP

    def _generate_prefix(self, container):
        """
        Generate the prefix for a log line without colour
        """
        color = container.environment.get("COLOR", "white")
        name = click.style(container.hostname, fg=color)
        padding = ' ' * (self.prefix_width - len(container.hostname))
        return ''.join([name, padding, ' | '])

    def _attach(self, container):
        params = {
            'stdout': True,
            'stderr': True,
            'stream': True,
            'logs': True,
        }
        return container.attach(**params)


@click.command('logs')
@click.argument('hostname', required=False, default="")
@pass_state
@pass_context
def cli(ctx, state, hostname):
    """Fetch the logs of all containers."""
    containers = list(ctx.get_containers(state))
    if hostname:
        node_name = ''.join([i for i in hostname if not i.isdigit()])
        nodes = ("frontend", "services", "node", "server")
        if not node_name in nodes:
            raise click.ClickException("Cannot find the container with the "
                                       "name '%s'" % hostname)
        containers = [c for c in containers if c.hostname == hostname]
    if not containers:
        print_msg = "container" if hostname else "containers"
        raise click.ClickException("The %s must be started before "
                                   "running this command. Run  `oardocker"
                                   " start` first" % print_msg)
    else:
        LogPrinter(containers).run()
