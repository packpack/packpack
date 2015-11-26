import os
import sys

from debuilder import BuildConfig
from debuilder.steps import create_or_cleanup, change_directory
from debuilder.utils import DCH, DPKG
from debuilder.executable import Executable, ExecutableError

class Builder(Executable):
    def __init__(self):
        super(Builder, self).__init__()
        self.command = 'debuild -b -uc -us'

    def __call__(self):
        self.execute()
        

class CleanBuilder(BuildConfig):
    def __init__(self, product, distro, arch, image=None, output=None):
        self.distro = distro
        self.product = product
        self.arch = arch
        self.dsc = None
        self.changes = None
        self.exe = {
            'dch': DCH(),
            'dpkg': DPKG(),
            'builder': Builder()
        }

        if output is not None: 
            for key in self.variables.keys():
                self.variables[key][0] = output

        for i in ['builddir', 'resultdir']:
            path = os.path.join(*self.variables[i])
            path = path.format(distro=distro['distro'], arch=arch)
            try:
                create_or_cleanup(path)
                setattr(self, i, path)
            except OSError as e:
                exit(1)

    def build_sourcecode(self):
        path_to = os.path.join(*self.variables['gitpath']).format(
            distro=self.distro['distro'],
            arch=self.arch,
            product=''
        )

        new_dir = '{product}-{version}'.format(
            product=self.product['product'],
            version=self.deb_version
        )

        with change_directory('%s/%s' % (path_to, new_dir)):
            self.exe['builder']()

os_name = sys.argv[1]
dist_name = sys.argv[2]
branch = sys.argv[3]
product_name = sys.argv[4]
product_uri = sys.argv[5]
arch = 'amd64'

product = {
    'branch': branch,
    'product': product_name,
    'sign_id': '',
    'sign_email': '',
    'git': product_uri
}

dist = {
    'distro': dist_name,
    'os': os_name,
    'arches': [arch, ]
}
builder = CleanBuilder(product, dist, arch)
builder.prepare_sourcecode()
builder.build_sourcecode()
