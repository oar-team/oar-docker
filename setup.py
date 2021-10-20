import os.path as op
from setuptools import setup, find_packages
from oardocker import VERSION

here = op.abspath(op.dirname(__file__))


def read(fname):
    ''' Return the file content. '''
    with open(op.join(here, fname)) as f:
        return f.read()


setup(
    name='oar-docker',
    author='Salem Harrache',
    author_email='salem@harrache.info',
    version=VERSION,
    url='https://oar.imag.fr/wiki:oar-docker',
    setup_requires=['wheel'],
    install_requires=[
        'Click',
        'docker',
        'sh',
        'tabulate',
        'arrow',
    ],
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    description='Manage a small OAR developpement cluster with docker.',
    long_description=read('README.rst') + '\n\n' + read('CHANGES.rst'),
    classifiers=[
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
    ],
    entry_points='''
        [console_scripts]
        oardocker=oardocker.cli:main
    ''',
)
