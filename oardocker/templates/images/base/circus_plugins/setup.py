from setuptools import setup, find_packages

setup(
    name='circus-oardocker',
    author='Salem Harrache',
    author_email='salem.harrache@inria.fr',
    version='0.0.1',
    install_requires=[
        'psycopg2',
    ],
    packages=find_packages(),
    zip_safe=True,
    description='Oar-docker custom circus plugins.',
)
