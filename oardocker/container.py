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
        privileged = options.pop('privileged', False)
        port_bindings = options.pop('port_bindings', {})
        binds = options.pop('binds', None)
        volumes_from = options.pop('volumes_from', [])
        network_name = options.pop('network_name', None)

        host_config_kwargs = {
            "tmpfs": {'/run/lock': '', '/run': '', '/tmp': ''},
            "security_opt": ['seccomp:unconfined'],
            "cap_add": ["SYS_ADMIN", "MKNOD"],
        }
        if binds:
            host_config_kwargs['binds'] = binds
        if privileged:
            host_config_kwargs['privileged'] = privileged
        if port_bindings:
            host_config_kwargs['port_bindings'] = port_bindings
        if volumes_from:
            host_config_kwargs['volumes_from'] = volumes_from

        if network_name:
            if "hostname" in options:
                endpoint_config = docker.api.create_endpoint_config(
                    aliases=[options['hostname']],
                )
            else:
                endpoint_config = docker.api.create_endpoint_config()
            options['networking_config'] = docker.api.create_networking_config({
                network_name: endpoint_config
            })
        if host_config_kwargs:
            options['host_config'] = docker.api.create_host_config(**host_config_kwargs)

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

    def nodename(self):
        return ''.join([i for i in self.hostname if not i.isdigit()])

    @property
    def ip(self):
        self.inspect_if_not_inspected()
        return self.dictionary["NetworkSettings"]["Networks"][self.docker.ctx.network_name]["IPAddress"]

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
        follow = kwargs.pop("follow", False)
        if follow:
            lines = kwargs.pop("lines", 10)
        else:
            lines = kwargs.pop("lines", "all")
        _iter = kwargs.pop("_iter", False)
        if _iter:
            call_args = ["logs"]
            call_args.extend(["--tail", "%s" % lines])
            if follow:
                call_args.append("--follow")
            call_args.append(self.id)
            return self.docker.cli(call_args, _iter=_iter)
        else:
            return to_unicode(self.docker.api.logs(self.id, *args, **kwargs))

    def get_log_prefix(self, prefix_width=None):
        """
        Generate the prefix for a log line without colour
        """
        if prefix_width is None:
            prefix_width = len(self.hostname)
        color = self.environment.get("COLOR", "white")
        name = click.style(self.hostname, fg=color)
        padding = ' ' * (prefix_width - len(self.hostname))
        return ''.join([padding, name, ' | '])

    def inspect(self):
        self.dictionary = self.docker.api.inspect_container(self.id)
        return self.dictionary

    def execute(self, cmd, user, workdir, tty):
        tty_option = "t" if tty else ""
        return self.docker.cli(["exec", "-i%s" % tty_option, self.id,
                                "setuser", user, "script", "-q", "/dev/null",
                                "-c", "exec_in_container %s '%s'"
                                % (workdir, cmd)])

    def __repr__(self):
        return '<Container: %s>' % self.name

    def __eq__(self, other):
        if type(self) != type(other):
            return False
        return self.id == other.id
