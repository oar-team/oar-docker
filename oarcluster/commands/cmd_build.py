import glob
import os.path as op
import re
import shutil
import sys
import tarfile
import urllib

import click
from oarcluster.cli import pass_context
from oarcluster.utils import sha1_checksum, stream_output


@click.command('build')
@click.argument('tarball', required=False)
@click.option('--cache/--no-cache', default=True)
@pass_context
def cli(ctx, tarball, cache):
    """Build oarcluster images"""
    ctx.assert_valid_env()
    ctx.log('Starting oarcluster build')
    if tarball is None:
        tarball = ctx.oar_tarball
    # Prepare OAR archive "oar-tarball.tar.gz"
    if not op.isfile(tarball):
        filename = "archive_%s.tar.gz" % sha1_checksum(tarball)
        filepath = op.join(ctx.envdir, filename)
        if not op.isfile(filepath) or not cache:
            print("Downloading tarball from %s" % ctx.oar_tarball)
            urllib.urlretrieve(ctx.oar_tarball, filepath)
        else:
            print("Using cached tarball")
        ctx.oar_tarball = filepath
    # Prepare version.txt file "version.txt"
    with tarfile.open(ctx.oar_tarball) as tar:
        if tar.getmembers()[0].name == ".":
            first_file = tar.getmembers()[1].name
        else:
            first_file = tar.getmembers()[0].name
        rg = re.compile(r'oar-(\d[0-9.]+)', re.IGNORECASE | re.DOTALL)
        result = rg.search(first_file)
        if result:
            ctx.oar_version = result.group(1)
    if not op.isfile(ctx.oar_version_file):
        with open(op.join(ctx.workdir, ctx.oar_version_file), "w+") as f:
            f.write(ctx.oar_version)
    dockerfiles = glob.glob(op.join(ctx.templates_dir, "images", "*",
                            "Dockerfile"))
    dockerfiles.sort()
    for dockerfile in dockerfiles:
        dirname = op.dirname(dockerfile)
        name = op.basename(dirname)
        tag = "%s/%s:%s" % (ctx.prefix, name, ctx.version)
        oar_tarball = op.join(dirname, "oar-tarball.tar.gz")
        oar_version_file = op.join(dirname, "version.txt")
        shutil.copy2(ctx.oar_tarball, oar_tarball)
        shutil.copy2(ctx.oar_version_file, oar_version_file)
        ## Docker build
        build_output = ctx.docker.build(path=dirname, tag=tag, rm=True,
                                        quiet=False, stream=True,
                                        nocache=(not cache))
        stream_output(build_output, sys.stdout)
