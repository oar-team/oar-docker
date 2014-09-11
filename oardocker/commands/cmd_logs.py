from __future__ import unicode_literals

from Queue import Queue, Empty
from threading import Thread

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

    def loop(self):
        self._init_readers()

        while True:
            try:
                item = self.queue.get(timeout=0.1)
                if item is STOP:
                    break
                else:
                    yield item
            except Empty:
                pass

    def _init_readers(self):
        for generator in self.generators:
            t = Thread(target=_enqueue_output, args=(generator, self.queue))
            t.daemon = True
            t.start()


def _enqueue_output(generator, queue):
    for item in generator:
        queue.put(item)


class LogPrinter(object):
    def __init__(self, containers, attach_params=None):
        self.containers = containers
        self.attach_params = attach_params or {}
        self.prefix_width = self._calculate_prefix_width(containers)
        self.generators = self._make_log_generators()

    def run(self):
        mux = Multiplexer(self.generators)
        for line in mux.loop():
            click.echo(line, nl=False)

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
        }
        params.update(self.attach_params)
        params = dict((name, 1 if value else 0) for (name, value) in list(params.items()))
        return container.attach(**params)


@click.command('logs')
@click.option('-f', '--follow', is_flag=True, default=False,
              help="Follow log output")
@pass_state
@pass_context
def cli(ctx, state, follow):
    """Fetch the logs of all containers."""
    containers = list(ctx.get_containers(state))
    if not containers:
        click.echo("Nothing to see !")
    else:
        LogPrinter(containers, attach_params={'logs': True}).run()
