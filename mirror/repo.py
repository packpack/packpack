from posixpath import join as pathjoin
import subprocess
import requests

API_URL = "https://packagecloud.io/"
API_USER = "tarantool"

class RepoManager(object):
    """
    Repository Manager for cloud builds
    Usage:
    m = RepoManager("my_token")
    
    # cleanup old versions
    m.prune_all()

    # init mirrors
    m.mirror_deb()
    m.mirror_rpm()

    # update mirrors and push changes
    m.update_mirrors()
    """
    DISRS = {
        'rpm': [
            {'os': "fedora", 'dist': '22'},
            {'os': "fedora", 'dist': '23'},
            {'os': "el", 'dist': '6'},
            {'os': "el", 'dist': '7'},
        ],
        'deb': [
            {'os': "ubuntu", 'dist': 'trusty'},
            {'os': "ubuntu", 'dist': 'precise'},
            {'os': "ubuntu", 'dist': 'wily'},
            {'os': "ubuntu", 'dist': 'xenial'},
            {'os': "debian", 'dist': 'jessie'},
            {'os': "debian", 'dist': 'wheezy'},
            {'os': "debian", 'dist': 'stretch'},
        ]
    }

    def __init__(self, token, user=API_USER, url=API_URL, limit=2):
        self.api_url = url
        self.auth = (token, '')
        self.api_user = user
        self.version_limit = limit
        self.repos = self.get(pathjoin("api", "v1", "repos"))

    def api_path(self, path):
        return '%s%s' % (self.api_url, path)

    def get(self, path):
        """
        Api request
        """
        resp = requests.get(self.api_path(path), auth=self.auth)
        resp.raise_for_status()
        return resp.json()

    def prune_package(self, name, path):
        """
        Drop package from package cloud
        """
        print('prune', name, path)
        resp = requests.delete(self.api_path(path), auth=self.auth)
        resp.raise_for_status()

    def prune_versions(self, repo, name, path):
        """
        Get package versions list and delete
        old versions up to versions_limit
        """
        versions = sorted(
            self.get(path),
            key=lambda v: v['created_at']
        )

        for version in versions[:-self.version_limit]:
            distro_version = version["distro_version"]
            filename = version["filename"]
            pkgpath = pathjoin(
                "api", "v1", "repos", self.api_user, repo,
                distro_version, filename
            )
            self.prune_package(name, pkgpath)

    def prune_repo(self, repo, kind):
        """
        Get all packages list in repo and prune old versions
        """
        path = pathjoin(
            "api", "v1", "repos", self.api_user,
            repo, "packages", "{}.json".format(kind)
        )
        packages = self.get(path)
        for package in packages:
            name = package['name']
            self.prune_versions(repo, name, package['versions_url'])

    def prune_all(self):
        """
        Prune repo wrapper: get all repos and prune it
        """
        for repo in self.repos:
            for kind in self.DISRS.keys():
                self.prune_repo(repo['name'], kind)

    def aptly_update(self, repo, alias=None):
	result = []
        if alias is None:
            alias = repo_name
        for conf in self.DISRS['deb']:
            name = '%s_%s' % (alias, conf['dist'])
	    result.append([
            	"aptly", "mirror", "update",
                "-ignore-checksums=true", name
   	    ])
	return result

    def mirror_deb(self, repo_name, alias=None):
        """
        Create debian based mirrors from packagecloud.io
        """
        print 'Mirror creation start'
        if alias is None:
            alias = repo_name
        cmds = []
        for conf in self.DISRS['deb']:
            cmds.append([
                'aptly', 'mirror', 'create', 
                '-with-sources=true', '%s_%s' % (alias, conf['dist']),
                '%s%s/%s/%s' % (self.api_url, self.api_user, repo_name, conf['os']),
                conf['dist']
            ])
        cmds.extend(self.aptly_update(repo_name, alias))
        for conf in self.DISRS['deb']:
            name = '%s_%s' % (alias, conf['dist'])
            cmds.append([
                "aptly", "snapshot", "create",
                name, "from", "mirror", name
            ])
            cmds.append([
                "aptly", "publish", "snapshot",
                "-force-overwrite=true", "-skip-signing=true",
                name, name
            ])
        for cmd in cmds:
            self.run(cmd)
        print 'Mirror creation done'



    def mirror_rpm(self, repo_name, alias=None):
        """
        Create rpm mirrors from packagecloud.io
        """
        raise NotImplementedError

    def update_rpms(self, repo_name, alias=None):
        raise NotImplementedError

    def update_mirrors(self, repo_name, alias=None):
        """
        Update mirrors and push all changes to local repositories
        """
        self.update_debs(repo_name, alias)
        #self.update_rpms(repo_name, alias)

    def update_debs(self, repo_name, alias=None):
        """
        Update debian repos with aptly
        """
        print "Update start"
        if alias is None:
            alias = repo_name
        cmds = []
        # update repos
        cmds.extend(self.aptly_update(repo_name, alias))
        for conf in self.DISRS['deb']:
            name = '%s_%s' % (alias, conf['dist'])
            # rename old snapshot
            cmds.append([
                "aptly", "snapshot", "rename",
                name, "%s-old" % name
            ])
            # create new snapshot
            cmds.append([
                "aptly", "snapshot", "create",
                name, "from", "mirror", name
            ])
            # switch old and new
            cmds.append([
                "aptly", "publish", "switch",
                "-force-overwrite=true", "-skip-signing=true",
                conf['dist'], name, name
            ])
            # remove old snapshot
            cmds.append([
                "aptly", "snapshot", "drop", "%s-old" % name
            ])
        for cmd in cmds:
            self.run(cmd)
        print 'Update done'
        

    def run(self, cmd):
        print ' '.join(cmd)
        p = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        out, err = p.communicate()
        print out
	print err
        return err
