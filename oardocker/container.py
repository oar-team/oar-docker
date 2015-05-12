# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import click
from .compat import to_unicode


class Container(object):

    def __init__(self, docker, dictionary, has_been_inspected=False):
        self.docker = docker
        self.dictionary = dictionary
        self.has_been_inspected = has_been_inspected

    @classmethod
    def from_id(cls, docker, cid):
        return cls(docker, docker.api.inspect_container(cid), True)

    @classmethod
    def from_name(cls, docker, name):
        containers = docker.api.containers(quiet=False, all=True,
                                           trunc=False, latest=False)
        for container in containers:
            cname = ''.join(container["Names"] or []).lstrip("/")
            if not cname == name:
                continue
            return cls(docker, container)
        raise Exception("Cannot find a container with name '%s'" % name)

    @classmethod
    def create(cls, docker, **options):
        response = docker.api.create_container(**options)
        return cls(docker, response)

    @property
    def id(self):
        return self.dictionary['Id']

    @property
    def image(self):
        return self.dictionary['Image']

    @property
    def short_id(self):
        return self.id[:12]

    @property
    def name(self):
        return ''.join(self.dictionary["Name"]).lstrip("/")

    @property
    def image_name(self):
        self.inspect_if_not_inspected()
        return self.dictionary['Config']['Image']

    @property
    def human_readable_ports(self):
        self.inspect_if_not_inspected()
        if not self.dictionary['NetworkSettings']['Ports']:
            return ''
        ports = []
        items = self.dictionary['NetworkSettings']['Ports'].items()
        for private, public in list(items):
            if public:
                ports.append('%s->%s' % (public[0]['HostPort'], private))
            else:
                ports.append(private)
        return ', '.join(ports)

    @property
    def human_readable_state(self):
        self.inspect_if_not_inspected()
        if self.dictionary['State']['Running']:
            if self.dictionary['State'].get('Ghost'):
                return 'Ghost'
            else:
                return 'Up'
        else:
            return 'Exit %s' % self.dictionary['State']['ExitCode']

    @property
    def human_readable_command(self):
        self.inspect_if_not_inspected()
        if self.dictionary['Config']['Cmd']:
            return ' '.join(self.dictionary['Config']['Cmd'])
        else:
            return ''

    @property
    def hostname(self):
        self.inspect_if_not_inspected()
        return self.dictionary["Config"]["Hostname"]

    @property
    def ip(self):
        self.inspect_if_not_inspected()
        return self.dictionary["NetworkSettings"]["IPAddress"]

    @property
    def environment(self):
        self.inspect_if_not_inspected()
        out = {}
        for var in self.dictionary.get('Config', {}).get('Env', []):
            k, v = var.split('=', 1)
            out[k] = v
        return out

    @property
    def is_running(self):
        self.inspect_if_not_inspected()
        return self.dictionary['State']['Running']

    def start(self, **options):
        return self.docker.api.start(self.id, **options)

    def stop(self, **options):
        return self.docker.api.stop(self.id, **options)

    def kill(self, signal="SIGKILL"):
        return self.docker.api.kill(self.id, signal)

    def commit(self, **options):
        return self.docker.api.commit(self.id, **options)

    def remove(self, **options):
        return self.docker.api.remove_container(self.id, **options)

    def inspect_if_not_inspected(self):
        if not self.has_been_inspected:
            self.inspect()
            self.has_been_inspected = True

    def wait(self):
        return self.docker.api.wait(self.id)

    def logs(self, *args, **kwargs):
        follow = kwargs.get("follow", False)
        tail = kwargs.get("tail", -1)
        _iter = kwargs.get("_iter", False)
        if _iter:
            call_args = ["logs"]
            if tail > 0:
                call_args.extend(["--tail", "%s" % tail])
            if follow:
                call_args.append("--follow")
            call_args.append(self.id)
            return self.docker.cli(call_args, _iter=_iter)
        else:
            return to_unicode(self.docker.api.logs(self.id, *args, **kwargs))

    def get_log_prefix(self, prefix_width):
        """
        Generate the prefix for a log line without colour
        """
        color = self.environment.get("COLOR", "white")
        name = click.style(self.hostname, fg=color)
        padding = ' ' * (prefix_width - len(self.hostname))
        return ''.join([padding, name, ' | '])

    def inspect(self):
        self.dictionary = self.docker.api.inspect_container(self.id)
        return self.dictionary

    def execute(self, cmd, user, workdir):
        return self.docker.cli(["exec", "-it", self.id,
                                "script", "-q", "/dev/null", "-c",
                                "exec setuser %s /bin/bash -ilc "
                                "'exec_in_container %s %s'"
                                % (user, workdir, cmd)])

    def __repr__(self):
        return '<Container: %s>' % self.name

    def __eq__(self, other):
        if type(self) != type(other):
            return False
        return self.id == other.id
