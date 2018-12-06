# -*- coding: utf-8 -*-
from __future__ import with_statement, absolute_import, unicode_literals

import os
import os.path as op
import sys

from io import open
from functools import update_wrapper

import click

from .state import State
from .client import Docker
from .compat import basestring, reraise


CONTEXT_SETTINGS = dict(auto_envvar_prefix='oardocker',
                        help_option_names=['-h', '--help'])


class Context(object):

    def __init__(self):
        self.current_dir = os.getcwd()
        self.verbose = False
        self.workdir = self.current_dir
        self.cgroup_path = None
        # oar archive url
        self.oar_website = "http://oar-ftp.imag.fr/oar/2.5/sources/stable"
        self.oar_tarball = "%s/oar-2.5.3.tar.gz" % self.oar_website
        self.prefix = "oardocker"
        self.debug = False

    def init_workdir(self, env_name, env_id):
        with open(self.env_name_file, "w+") as fd:
            fd.write(env_name + "\n")
        if not os.path.exists(self.env_id_file):
            with open(self.env_id_file, "w+") as fd:
                fd.write(env_id + "\n")

    @property
    def tmp_workdir(self):
        tmp_dir = op.join(self.envdir, "tmp")
        if not os.path.isdir(tmp_dir):
            os.makedirs(tmp_dir)
        return tmp_dir

    @property
    def env_name(self):
        with open(self.env_name_file) as env_file:
            return env_file.read().strip()

    @property
    def env_id(self):
        with open(self.env_id_file) as env_file:
            return env_file.read().strip()

    def image_name(self, node, tag=""):
        if not tag == "":
            tag = ":%s" % tag
        if not self.env_name == "default":
            return "%s/%s-%s%s" % (self.prefix, self.env_name, node, tag)
        else:
            return "%s/%s%s" % (self.prefix, node, tag)

    @property
    def state(self):
        if not hasattr(self, '_state'):
            self._state = State(self,
                                state_file=self.state_file,
                                manifest_file=self.manifest_file)
        return self._state

    def update(self):
        self.envdir = op.join(self.workdir, ".%s" % self.prefix)
        self.postinstall_dir = op.join(self.envdir, "postinstall")
        self.manifest_file = op.join(self.envdir, "manifest.json")
        self.env_name_file = op.join(self.envdir, "env_name")
        self.env_id_file = op.join(self.envdir, "env_id")
        self.state_file = op.join(self.envdir, "state.json")
        self.nodes_file = op.join(self.envdir, "nodes")
        self.cow_volumes_file = op.join(self.envdir, "cow_volumes")
        self.systemd_config_file = op.join(self.envdir, "systemd.conf")
        self.etc_profile_file = op.join(self.envdir, "profile.sh")
        self.docker = Docker(self, self.docker_host, self.docker_binary)

    @property
    def network_name(self):
        return "%s_%s" % (self.prefix, self.env_id)

    def assert_valid_env(self):
        if not os.path.isdir(self.envdir):
            raise click.ClickException("Missing oardocker env directory."
                                       " Run `oardocker init` to create"
                                       " a new oardocker environment")

    def log(self, msg, *args, **kwargs):
        """Logs a message to stdout."""
        if args:
            msg %= args
        kwargs.setdefault("file", sys.stdout)
        click.echo(msg, **kwargs)

    def wlog(self, msg, *args):
        """Logs a warning message to stderr."""
        self.log(click.style("Warning: %s" % msg, fg="yellow"), *args, file=sys.stderr)

    def vlog(self, msg, *args):
        """Logs a message to stderr only if verbose is enabled."""
        if self.verbose:
            self.log(msg, *args, **{'file': sys.stderr})

    def handle_error(self):
        exc_type, exc_value, tb = sys.exc_info()
        if not self.debug:
            sys.stderr.write(u"\nError: %s\n" % exc_value)
            sys.exit(1)
        else:
            reraise(exc_type, exc_value, tb.tb_next)


def make_pass_decorator(ensure=False):
    def decorator(f):
        @click.pass_context
        def new_func(*args, **kwargs):
            ctx = args[0]
            if ensure:
                obj = ctx.ensure_object(Context)
            else:
                obj = ctx.find_object(Context)
            try:
                return ctx.invoke(f, obj, *args[1:], **kwargs)
            except:
                obj.handle_error()
        return update_wrapper(new_func, f)
    return decorator


pass_context = make_pass_decorator(ensure=True)


class DeprecatedCmdDecorator(object):
    """This is a decorator which can be used to mark cmd as deprecated. It will
    result in a warning being emmitted when the command is invoked."""

    def __init__(self, message=""):
        if message:
            self.message = "%s." % message
        else:
            self.message = message

    def __call__(self, f):

        @click.pass_context
        def new_func(ctx, *args, **kwargs):
            msg = click.style("warning: `%s` command is deprecated. %s" %
                              (ctx.info_name, self.message), fg="yellow")
            click.echo(msg)
            return ctx.invoke(f, *args, **kwargs)

        return update_wrapper(new_func, f)


class OnStartedDecorator(object):
    def __init__(self, callback):
        self.callback = callback
        self.exec_before = True

    def invoke_callback(self, ctx):
        if isinstance(self.callback, basestring):
            cmd = ctx.parent.command.get_command(ctx, self.callback)
            ctx.invoke(cmd)
        else:
            self.callback(ctx.obj)

    def __call__(self, f):
        @click.pass_context
        def new_func(ctx, *args, **kwargs):
            try:
                if self.exec_before:
                    self.invoke_callback(ctx)
                return ctx.invoke(f, *args, **kwargs)
            finally:
                if not self.exec_before:
                    self.invoke_callback(ctx)
        return update_wrapper(new_func, f)


class OnFinishedDecorator(OnStartedDecorator):
    def __init__(self, callback):
        super(on_finished, self).__init__(callback)
        self.exec_before = False


deprecated_cmd = DeprecatedCmdDecorator
on_started = OnStartedDecorator
on_finished = OnFinishedDecorator
