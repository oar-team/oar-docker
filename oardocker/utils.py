# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals

import filecmp
import hashlib
import os
import os.path as op
import re
import random
import shutil
import socket
import string
import tarfile

import click
import requests

from io import open
from sh import ErrorReturnCode

from .compat import _out, _err, to_unicode


def git(*args, **kwargs):
    try:
        from sh import git as git_cmd
    except ImportError:
        raise Exception('git is missing, please install it before using this'
                        ' command')
    return git_cmd(*args, **kwargs)


def check_tcp_port_open(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect((ip, int(port)))
        s.close()
        return True
    except:
        return False


def touch(fname, times=None):
    dirname = '/'.join(fname.split('/')[:-1])
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    with open(fname, 'a'):
        os.utime(fname, times)


def empty_file(path):
    touch(path)
    open(path, 'w').close()


def append_file(path, content):
    with open(path, "a+") as fd:
        fd.write(content)


def sha1_checksum(string):
    return hashlib.sha1(string).hexdigest()


def check_tarball(path):
    try:
        with tarfile.open(path):
            return True
    except:
        return False


def check_git(path):
    try:
        git("--git-dir", op.join(path, ".git"), "--work-tree", path, "status")
        return True
    except ErrorReturnCode:
        return False


def check_url(name):
    """Returns true if the name looks like a URL"""
    if ':' not in name:
        return False
    scheme = name.split(':', 1)[0].lower()
    return scheme in ['http', 'https', 'file', 'ftp']


def git_pull_or_clone(src, dest):
    if op.exists(dest):
        remote_url = git("--git-dir", op.join(dest, ".git"),
                         "--work-tree", dest, "config",
                         "--get", "remote.origin.url")
        if remote_url.rstrip() == src:
            git("--git-dir", op.join(dest, ".git"), "--work-tree",
                dest, "pull", "--progress", _out=_out, _err=_err)
        else:
            shutil.rmtree(dest)
    else:
        git("clone", src, dest, "--progress", _out=_out, _err=_err)


def download_file(file_url, dest):
    req = requests.get(file_url)
    total_length = int(req.headers['Content-Length'].strip())

    def stream():
        for chunk in req.iter_content(chunk_size=1024):
            yield chunk
    with open(dest, 'wb+') as f:
        with click.progressbar(stream(),
                               length=((total_length / 1024) + 1)) as bar:
            for chunk in bar:
                f.write(chunk)
                f.flush()


def random_key(length):
    """Returns a random alphanumeric string of length 'length'"""
    key = ''
    for i in range(length):
        key += random.choice(string.lowercase + string.uppercase +
                             string.digits)
        return key


def copy_file(srcname, dstname, preserve_symlinks=True):
    if preserve_symlinks and os.path.islink(srcname):
        if os.path.islink(dstname):
            os.unlink(dstname)
        else:
            os.remove(dstname)
        linkto = os.readlink(srcname)
        os.symlink(linkto, dstname)
    else:
        if os.path.islink(dstname):
            os.unlink(dstname)
        shutil.copy2(srcname, dstname)


def copy_tree(src, dest, overwrite=False, ignore_if_exists=[]):
    """
    Copy all files in the source path to the destination path.
    """
    if os.path.exists(dest) and not overwrite:
        raise click.ClickException("File exists : '%s'" % dest)
    create = click.style('   create', fg="green")
    chmod = click.style('    chmod', fg="cyan")
    overwrite = click.style('overwrite', fg="yellow")
    identical = click.style('identical', fg="blue")
    ignore = click.style('   ignore', fg="magenta")
    cwd = os.getcwd() + "/"
    initd_path = op.join(src, "my_init.d")
    for path, dirs, files in os.walk(src):
        relative_path = path[len(src):].lstrip(os.sep)
        if not op.exists(op.join(dest, relative_path)):
            os.mkdir(op.join(dest, relative_path))
        for filename in files:
            src_file_path = op.join(path, filename)
            dest_file_path = op.join(dest, relative_path, filename)
            if dest_file_path.startswith(cwd):
                fancy_relative_path = dest_file_path.replace(cwd, "")
            else:
                fancy_relative_path = dest_file_path
            if op.exists(dest_file_path):
                if filename in ignore_if_exists:
                    click.echo("   " + ignore + "  " + fancy_relative_path)
                elif filecmp.cmp(src_file_path, dest_file_path):
                    click.echo("   " + identical + "  " + fancy_relative_path)
                else:
                    click.echo("   " + overwrite + "  " + fancy_relative_path)
                    copy_file(src_file_path, dest_file_path)
            else:
                click.echo("   " + create + "  " + fancy_relative_path)
                copy_file(src_file_path, dest_file_path)
            if (src_file_path.startswith(initd_path) or
                    "bin/" in dest_file_path):
                if not os.path.islink(dest_file_path):
                    if not os.access(dest_file_path, os.X_OK):
                        os.system("chmod +x %s" % dest_file_path)
                        click.echo("   " + chmod + "  " + fancy_relative_path)


def human_filesize(bytes):
    """Human-readable file size.
    """
    for x in ['bytes', 'KB', 'MB', 'GB']:
        if bytes < 1024.0:
            return "%3.1f %s" % (bytes, x)
        bytes /= 1024.0
    return "%3.1f %s" % (bytes, 'TB')


def find_executable(executable):
    path = os.environ['PATH']
    paths = path.split(os.pathsep)
    base, ext = os.path.splitext(executable)

    if not os.path.isfile(executable):
        for p in paths:
            f = os.path.join(p, executable)
            if os.path.isfile(f):
                # the file exists, we have a shot at spawn working
                return f
        return None
    else:
        return executable


def slugify(s):
    """
    Simplifies ugly strings into something URL-friendly.
    From: http://dolphm.com/slugify-a-string-in-python/

    >>> print slugify("[Some] _ Article's Title--")
    some-articles-title

    """
    s = to_unicode(s)
    s = s.lower()
    for c in [' ', '-', '.', '/']:
        s = s.replace(c, '_')
    s = re.sub('\W', '', s)
    s = s.replace('_', ' ')
    s = re.sub('\s+', ' ', s)
    s = s.strip()
    s = s.replace(' ', '-')

    return s
