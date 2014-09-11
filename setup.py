import re
import ast
from setuptools import setup


_version_re = re.compile(r'__version__\s+=\s+(.*)')


with open('oardocker/__init__.py', 'rb') as f:
    version = str(ast.literal_eval(_version_re.search(
        f.read().decode('utf-8')).group(1)))


setup(
    name='oardocker',
    author='Salem Harrache',
    author_email='salem.harrache@inria.fr',
    version=version,
    url='https://github.com/oar-team/docker-oardocker',
    install_requires=[
        'Click',
        'docker-py',
        'sh',
        'tabulate',
        'arrow',
        'dockerpty',
    ],
    packages=['oardocker'],
    description='Dockerfiles to build oar images for testing and development.',
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
