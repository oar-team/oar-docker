SHELL := /bin/bash

# these files should pass flakes8
FLAKE8_WHITELIST=$(shell find . -name "*.py" \
                    ! -path "./docs/*" ! -path "./.tox/*" \
                    ! -path "./env/*" ! -path "./venv/*" \
                    ! -path "**/compat.py" ! -path "./kameleon/*")

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  init       to install the project in development mode (using virtualenv is highly recommended)"
	@echo "  clean      to remove build and Python file (.pyc) artifacts"
	@echo "  lint       to check style with flake8"
	@echo "  sdist      to package"
	@echo "  release    to package and upload a release"
	@echo "  bumpversion to bump the release version number"
	@echo "  newversion  to set the new development version"

init:
	pip install -e .
	pip install -U setuptools pip tox ipdb jedi pytest pytest-cov flake8 wheel bumpversion

clean:
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info
	find . -name '*.pyc' -type f -exec rm -f {} +
	find . -name '*.pyo' -type f -exec rm -f {} +
	find . -name '*~' -type f -exec rm -f {} +
	find . -name '__pycache__' -type d -exec rm -rf {} +

lint:
	flake8 $(FLAKE8_WHITELIST)

sdist: clean
	python setup.py sdist
	ls -l dist

release: clean
	python setup.py register
	python setup.py sdist upload
	python setup.py bdist_wheel upload

bumpversion:
	@python scripts/bumpversion.py release

newversion:
	@python scripts/bumpversion.py newversion $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
