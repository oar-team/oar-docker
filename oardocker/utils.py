import codecs
import filecmp
import hashlib
import json
import os
import os.path as op
import random
import shutil
import socket
import string
import sys
import tarfile

import click
import requests
from sh import git, ErrorReturnCode


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
    with file(fname, 'a'):
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
        with open(os.devnull, 'w') as devnull:
            git("--git-dir", op.join(path, ".git"), "--work-tree", path,
                "status", _out=devnull, _err=devnull)
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
                dest, "pull", "--progress", _out=sys.stdout, _err=sys.stderr)
        else:
            shutil.rmtree(dest)
    else:
        git.clone(src, dest, "--progress", _out=sys.stdout, _err=sys.stderr)


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


## From https://github.com/docker/fig/blob/master/fig/progress_stream.py
def stream_output(output, stream):
    is_terminal = hasattr(stream, 'fileno') and os.isatty(stream.fileno())
    stream = codecs.getwriter('utf-8')(stream)
    all_events = []
    lines = {}
    diff = 0

    for chunk in output:
        event = json.loads(chunk)
        all_events.append(event)

        if 'progress' in event or 'progressDetail' in event:
            image_id = event['id']

            if image_id in lines:
                diff = len(lines) - lines[image_id]
            else:
                lines[image_id] = len(lines)
                stream.write("\n")
                diff = 0

            if is_terminal:
                # move cursor up `diff` rows
                stream.write("%c[%dA" % (27, diff))

        print_output_event(event, stream, is_terminal)

        if 'id' in event and is_terminal:
            # move cursor back down
            stream.write("%c[%dB" % (27, diff))

        stream.flush()

    return all_events


def print_output_event(event, stream, is_terminal):
    if 'errorDetail' in event:
        raise click.ClickException(event['errorDetail']['message'])

    terminator = ''

    if is_terminal and 'stream' not in event:
        # erase current line
        stream.write("%c[2K\r" % 27)
        terminator = "\r"
        pass
    elif 'progressDetail' in event:
        return

    if 'time' in event:
        stream.write("[%s] " % event['time'])

    if 'id' in event:
        stream.write("%s: " % event['id'])

    if 'from' in event:
        stream.write("(from %s) " % event['from'])

    status = event.get('status', '')

    if 'progress' in event:
        stream.write("%s %s%s" % (status, event['progress'], terminator))
    elif 'progressDetail' in event:
        detail = event['progressDetail']
        if 'current' in detail:
            percentage = float(detail['current']) / float(detail['total']) * 100
            stream.write('%s (%.1f%%)%s' % (status, percentage, terminator))
        else:
            stream.write('%s%s' % (status, terminator))
    elif 'stream' in event:
        stream.write("%s%s" % (event['stream'], terminator))
    else:
        stream.write("%s%s\n" % (status, terminator))


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
        linkto = os.readlink(srcname)
        os.symlink(linkto, dstname)
    else:
        shutil.copy2(srcname, dstname)


def copy_tree(src, dest):
    """
    Copy all files in the source path to the destination path.
    """
    create = click.style('   create', fg="green")
    chmod = click.style('    chmod', fg="cyan")
    overwrite = click.style('overwrite', fg="yellow")
    identical = click.style('identical', fg="blue")
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
                if filecmp.cmp(src_file_path, dest_file_path):
                    click.echo("   " + identical + "  " + fancy_relative_path)
                else:
                    click.echo("   " + overwrite + "  " + fancy_relative_path)
                    copy_file(src_file_path, dest_file_path)
            else:
                click.echo("   " + create + "  " + fancy_relative_path)
                copy_file(src_file_path, dest_file_path)
            if src_file_path.startswith(initd_path) or "bin/" in dest_file_path:
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
