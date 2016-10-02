#!/usr/bin/env python3

import os
import sys
import subprocess
import shutil
import argparse
from collections import OrderedDict

import yaml
import logging

class Build():
    class Env: pass
    env = Env()

    def __init__(self):
        #
        # Create environment
        #
        self.env.__dict__ = os.environ.copy()
        script_path = os.path.realpath(__file__)
        self.env.SCRIPT_DIR = os.path.abspath(os.path.dirname(script_path))
        self.env.SOURCE_DIR = os.path.abspath(os.path.join(self.env.SCRIPT_DIR, ".."))

        # Configure yaml to preserve order
        _mapping_tag = yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG
        def dict_representer(dumper, data):
            return dumper.represent_dict(data.iteritems())
        def dict_constructor(loader, node):
            return OrderedDict(loader.construct_pairs(node))
        yaml.add_representer(OrderedDict, dict_representer)
        yaml.add_constructor(_mapping_tag, dict_constructor)

        #
        # Setup logging
        #
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

        self.log.info("## Tarantool/Build")

        #
        # Read configuration files
        #
        self.config = {}
        config_paths = [
            os.path.join(self.env.SOURCE_DIR, ".build.yml"),
            os.path.join(self.env.SCRIPT_DIR, "defaults.yml")
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
                # Already set, ignore
                if hasattr(self.env, k):
                    # Variable is already set, ignore
                    continue
                if type(v) is list:
                    # Execute command to get variable value
                    v = self.execute_all(v, cwd = self.env.SOURCE_DIR,
                                         pipe = True)[-1].strip()
                elif type(v) is int:
                    # Convert value to string
                    v = str(v)
                elif type(v) is not str:
                    self.log.error("Invalid env.%s entry", k)
                    os.exit(-1)
                setattr(self.env, k, v)

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

    def info(self):
        self.log.info("%s", "-" * 80)
        self.log.info("Product:          %s", self.env.PRODUCT)
        self.log.info("Version:          %s", self.env.VERSION)
        self.log.info("Release:          %s", self.env.RELEASE)
        self.log.info("Target:           %s %s (%s)",
                      self.env.OS, self.env.DIST, self.env.PACK)
        if getattr(self.env, "DOCKER_REPO", ''):
            self.log.info("Docker Repo:      %s", self.env.DOCKER_REPO)
            self.log.info("Docker Image:     %s", self.env.DOCKER_TAG)
        else:
            self.log.info("Docker:           %s",
                          "skipped - missing DOCKER_REPO")

        if getattr(self.env, 'PACKAGECLOUD_TOKEN', ''):
            self.log.info("PackageCloud:     %s", self.env.PACKAGECLOUD_REPO)
        else:
            self.log.info("PackageCloud:     %s",
                          "skipped - missing PACKAGECLOUD_TOKEN")
        self.log.info("Build Directory:  %s", self.env.BUILD_DIR)
        self.log.info("%s", "-" * 80)

    def command_tarball(self, args):
        self.log.info("## Tarball")
        self.execute_all(self.config.get('tarball', []),
                         cwd = self.env.SOURCE_DIR)
        self.env.TARBALL = self.execute("echo *.tar*", pipe = True,
                                        cwd = self.env.BUILD_DIR).strip()

    def command_build(self, args):
        self.command_tarball(args)
        self.log.info("## Build")
        self.execute_all(self.config.get('build', []),
                         cwd = self.env.SOURCE_DIR)

    def run(self, args):
        shutil.rmtree(self.env.BUILD_DIR, ignore_errors = True)
        os.makedirs(self.env.BUILD_DIR)
        method = getattr(build, 'command_' + args.command);
        method(args);

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
    # Legacy
    if args.without_docker:
        delattr(build.args, 'DOCKER_REPO')
    build.info()
    build.run(args)
