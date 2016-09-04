#!/usr/bin/env python3

import os
import sys
import subprocess
import shutil
import argparse
from urllib.parse import urlparse
import yaml
import logging

class Build():
    class Env: pass
    env = Env()

    def __init__(self):
        self.env.__dict__ = os.environ.copy()
        script_path = os.path.realpath(__file__)
        self.env.BUILD_DIR = os.path.abspath(os.path.dirname(script_path))
        self.env.SOURCE_DIR = os.path.abspath(os.path.join(self.env.BUILD_DIR, ".."))

        self.log = logging.getLogger('build')
        self.log.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s %(levelname)-5s: %(message)s')
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        console_handler.setLevel(logging.INFO)
        self.log.addHandler(console_handler)
        file_handler = logging.FileHandler('build.log')
        file_handler.setFormatter(formatter)
        file_handler.setLevel(logging.DEBUG)
        self.log.addHandler(file_handler)

        self.log.info("## INIT")

        self.config = {}
        config_paths = [
            os.path.join(self.env.SOURCE_DIR, ".build.yml"),
            os.path.join(self.env.BUILD_DIR, "defaults.yml")
        ]
        for config_path in config_paths:
            if not os.path.exists(config_path):
                continue
            self.log.info("Found %s configuration file", config_path)
            with open(config_path, 'r') as f:
                root = yaml.load(f)
            for k, v in root.get('build', {}).items():
                if not k in self.config:
                    self.config[k] = v
            for k, v in root.get('env', {}).items():
                if not hasattr(self.env, k):
                    setattr(self.env, k, v)

        if not getattr(self.env, 'OS', '') or not getattr(self.env, 'DIST', ''):
            self.env.OS = 'ubuntu'
            self.env.DIST = 'xenial'
        elif self.env.OS == 'centos':
            self.env.OS = 'el' # compatibility

        if getattr(self.env, "TRAVIS_REPO_SLUG", ''):
            self.log.info("Travis CI detected")
            (TRAVIS_REPO_USER, TRAVIS_REPO_NAME) = \
                self.env.TRAVIS_REPO_SLUG.split("/")
            if not getattr(self.env, 'PRODUCT'):
                self.env.PRODUCT = TRAVIS_REPO_NAME
            self.env.BRANCH = self.env.TRAVIS_BRANCH
            if not self.env.BRANCH in { branch: True for branch in
                                       self.env.ENABLED_BRANCHES.split() }:
                self.log.warn("Build skipped - the branch %s is not for packaging",
                              self.env.BRANCHE)
                sys.exit(0)
            if not getattr(self.env, 'PACKAGECLOUD_REPO', ''):
                self.env.PACKAGECLOUD_REPO = self.env.TRAVIS_REPO_USER +"/" + \
                    self.env.BRANCH.replace(".", "_")

                if TRAVIS_REPO_USER == "tarantool" and \
                   self.env.BRANCH == "master":
                    # TODO: upload all master branches from tarantool/X repos to tarantool/1_6
                    self.env.PACKAGECLOUD_REPO = "tarantool/1_6"
        else:
            self.log.info("Local build")
            if not hasattr(self.env, 'PRODUCT'):
                origin = str(self.execute("git config --get remote.origin.url",
                                          cwd = self.env.SOURCE_DIR,
                                          pipe = True)).strip()
                self.env.PRODUCT = os.path.splitext(os.path.basename(origin))[0]
            self.env.BRANCH = self.execute("git rev-parse --abbrev-ref HEAD",
                                           cwd = self.env.SOURCE_DIR,
                                           pipe = True).strip()
            if not hasattr(self.env, 'PACKAGECLOUD_REPO'):
                self.env.PACKAGECLOUD_REPO = self.env.USER + "/" + \
                    self.env.BRANCH.replace(".", "_")

        if self.env.DIST.isdigit():
            self.env.OSDIST= self.env.OS + self.env.DIST
        else:
            self.env.OSDIST= self.env.OS + "-" + self.env.DIST

        if not hasattr(self.env, 'DOCKER_REPO'):
            origin = str(self.execute("git config --get remote.origin.url",
                                    cwd = self.env.BUILD_DIR,
                                    pipe = True)).strip()
            self.env.DOCKER_REPO = urlparse(origin).path.lstrip('/').rstrip('.git')
        self.env.DOCKER_TAG = self.env.DOCKER_REPO + ":" + self.env.OSDIST

        if not hasattr(self.env, 'TARGET_DIR'):
            self.env.TARGET_DIR = os.path.join(self.env.BUILD_DIR, "root",
                                               self.env.OSDIST)

        self.log.debug("Configuration:\n---\n%s---",
                       yaml.dump({ "env": self.env.__dict__, "build": self.config},
                                 width=70, indent=2, default_flow_style=False))

    def execute(self, cmd, cwd = None, code = 0, pipe = False):
        if type(cmd) is list:
            cmd = " ".join(cmd)
        p = subprocess.Popen(cmd,
            stdout = pipe and subprocess.PIPE or None,
            shell = True,
            cwd = cwd, env = self.env.__dict__);
        self.log.info("%s", cmd)
        (out, err) = p.communicate()
        if p.returncode != code:
            self.log.error("Command %s exited with code: %s",
                            cmd, p.returncode)
            sys.exit(1)
        if pipe:
            return out.decode('utf-8')

    def execute_all(self, commands, pipe = False, **kwargs):
        if not type(commands) is list:
            commands = [ commands ]
        results = []
        for command in commands:
            results.append(self.execute(command, pipe = pipe, **kwargs))
        if pipe:
            return results

    def prepare(self):
        self.log.info("## VERSION")
        if not getattr(self.env, 'VERSION', '') or \
           not getattr(self.env, 'RELEASE', ''):
            (version, release) = self.execute_all(self.config.get('version', []),
                                                  cwd = self.env.SOURCE_DIR,
                                                  pipe = True)[-2:]
            self.env.VERSION = version.strip()
            self.env.RELEASE = release.strip()
        self.env.NAME = self.env.PRODUCT + "-" + self.env.VERSION
        self.log.info("%s", "-" * 80)
        self.log.info("Product:          %s", self.env.PRODUCT)
        self.log.info("Version:          %s", self.env.VERSION)
        self.log.info("Release:          %s", self.env.RELEASE)
        self.log.info("Target:           %s", self.env.OSDIST)
        self.log.info("Docker Image:     %s", self.env.DOCKER_TAG)
        if hasattr(self.env, 'PACKAGECLOUD_TOKEN'):
            self.log.info("PackageCloud:     %s", self.env.PACKAGECLOUD_REPO)
        else:
            self.log.info("PackageCloud:     %s",
                          "skipped - missing PACKAGECLOUD_TOKEN")
        self.log.info("%s", "-" * 80)

    def command_tarball(self, args):
        self.log.info("## TARBALL")
        shutil.rmtree(self.env.TARGET_DIR, ignore_errors = True)
        os.makedirs(self.env.TARGET_DIR)
        self.execute_all(self.config.get('tarball', []),
                         cwd = self.env.SOURCE_DIR)
        self.env.TARBALL = self.execute("echo *.tar*", pipe = True,
                                        cwd = self.env.TARGET_DIR).strip()

    def make(self, args):
        cmd = ['/usr/bin/env', '-i',
               'PRODUCT=' + self.env.PRODUCT,
               'NAME=' + self.env.NAME,
               'TARBALL=' + self.env.TARBALL,
               'VERSION=' + self.env.VERSION,
               'RELEASE=' + self.env.RELEASE,
               'make'
               ]
        self.execute(cmd, cwd=self.env.TARGET_DIR)

    def docker_make(self, args):
        wrapper = os.path.join(self.env.TARGET_DIR, 'userwrapper.sh')
        with open(wrapper, 'w') as f:
            f.write("#!/bin/sh" "\n"
                    "useradd -u " + str(os.getuid()) + " build" "\n"
                    "usermod -a -G wheel build" "\n"
                    "usermod -a -G adm build" "\n"
                    "usermod -a -G sudo build" "\n"
                    "su build -c $@" "\n")
        os.chmod(wrapper, 777)
        cmd = [ 'docker', 'run',
               '--volume', '"' + self.env.TARGET_DIR + ':/build"',
               '--volume', '"' + os.path.join(self.env.HOME, '.cache') + ':/ccache"',
               '-e', 'CCACHE_DIR=/ccache',
               '-e', 'PRODUCT=' + self.env.PRODUCT,
               '-e', 'NAME=' + self.env.NAME,
               '-e', 'TARBALL=' + self.env.TARBALL,
               '-e', 'VERSION=' + self.env.VERSION,
               '-e', 'RELEASE=' + self.env.RELEASE,
               '--workdir', '/build',
               '--rm=true',
               '--entrypoint=/build/userwrapper.sh',
               self.env.DOCKER_TAG,
               "make"
               ]
        self.execute(cmd, cwd="/tmp")

    def command_build(self, args):
        self.command_tarball(args)
        self.log.info("## Build")

        if self.env.OS in ("debian", "ubuntu"):
            shutil.copy(os.path.join(self.env.BUILD_DIR, "pack", "deb.mk"),
                        os.path.join(self.env.TARGET_DIR, "Makefile"))
            shutil.copytree(os.path.join(self.env.SOURCE_DIR, "debian/"),
                            os.path.join(self.env.TARGET_DIR, "debian/"))
        elif self.env.OS in ("el", "ol", "fedora", "scientific"):
            shutil.copy(os.path.join(self.env.BUILD_DIR, "pack", "rpm.mk"),
                        os.path.join(self.env.TARGET_DIR, "Makefile"))
            rpm_spec = self.env.PRODUCT + ".spec"
            shutil.copy(os.path.join(self.env.SOURCE_DIR, "rpm", rpm_spec),
                        os.path.join(self.env.TARGET_DIR, rpm_spec))

        if args.without_docker:
            self.make(args)
        else:
            self.docker_make(args)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build');
    subparsers = parser.add_subparsers(help='available commands')
    parser.set_defaults(command='build', without_docker = False)

    tarball_parser = subparsers.add_parser('tarball',
        help='create source tarball');
    tarball_parser.set_defaults(command='tarball');

    build_parser = subparsers.add_parser('build',
        help='create packages');
    build_parser.set_defaults(command='build');
    build_parser.add_argument("--without-docker",
        help="don't use docker for build",
        action='store_true',
        default=False)

    args = parser.parse_args()
    if not 'command' in args:
        parser.print_help()
        sys.exit(1)

    build = Build()
    build.prepare()
    method = getattr(build, 'command_' + args.command);
    method(args);
