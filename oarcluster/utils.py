import codecs
import hashlib
import json
import os
import codecs
import hashlib
import os.path as op
import filecmp
import click


def touch(fname, times=None):
    dirname = '/'.join(fname.split('/')[:-1])
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    with file(fname, 'a'):
        os.utime(fname, times)


def sha1_checksum(string):
    return hashlib.sha1(string).hexdigest()


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


# Returns a random alphanumeric string of length 'length'
def random_key(length):
    key = ''
    for i in range(length):
        key += random.choice(string.lowercase + string.uppercase +
                             string.digits)
        return key


def copy_file(srcname, dstname, preserve_symlinks=True):
    if preserve_symlinks and os.path.islink(srcname):
        linkto = os.readlink(srcname)
        os.symlink(linkto, dstname)
    else:
        shutil.copy2(srcname, dstname)


def copy_tree(src, dest):
    """
    Copy all files in the source path to the destination path.
    """
    create = click.style('  create', fg="green")
    overwrite = click.style('overwrite', fg="yellow")
    identical = click.style('identical', fg="blue")
    cwd = os.getcwd() + "/"
    for path, dirs, files in os.walk(src):
        relative_path = path[len(src):].lstrip(os.sep)
        if not op.exists(op.join(dest, relative_path)):
            os.mkdir(op.join(dest, relative_path))
        for i, subdir in enumerate(dirs):
            if subdir.startswith('.'):
                del dirs[i]
        for filename in files:
            src_file_path = op.join(path, filename)
            dest_file_path = op.join(dest, relative_path, filename)
            if dest_file_path.startswith(cwd):
                fancy_relative_path = dest_file_path.lstrip(cwd)
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
