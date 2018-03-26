import os
import subprocess
import tempfile

from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase
from ansible.module_utils._text import to_text

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()


class LookupModule(LookupBase):

    def run(self, private_keys, variables=None, **kwargs):

        ret = []

        for private_key in private_keys:
            display.debug("sshpubkey: lookup private_key starting with `%s`" % private_key[:40])
            
            # Create FIFO to pass private key to ssh-keygen
            tmp_dir = tempfile.mkdtemp()
            private_key_fifo = os.path.join(tmp_dir, "private.key")
            os.mkfifo(private_key_fifo, mode=0o600)

            # Create temp file for public key results
            public_key_tmpfile = os.path.join(tmp_dir, "public.key")

            # Use ssh-keygen -y to generate the correponding public key
            display.vvv("sshpubkey: calling `ssh-keygen -y -f %s > %s`" % (private_key_fifo, public_key_tmpfile))
            ssh_keygen = subprocess.Popen("ssh-keygen -y -f %s > %s" % (private_key_fifo, public_key_tmpfile), shell=True, stderr=subprocess.PIPE)

            # Output private key to FIFO
            with open(private_key_fifo, 'w') as pkf:
                display.vvv("sshpubkey: writing private key to fifo %s" % (private_key_fifo))
                pkf.write(private_key)

            # Wait for ssh-keygen to complete
            display.vvv("sshpubkey: waiting for ssh-keygen to complete")
            ssh_keygen_stderr = ssh_keygen.communicate()[1]
            display.vvv("sshpubkey: ssh-keygen returned %d" % (ssh_keygen.returncode))

            # Check ssh-keygen results
            if ssh_keygen.returncode != 0:
                raise AnsibleError("could not lookup public key for private key starting with `%s`: %s" % (private_key[:40], ssh_keygen_stderr))

            # Get public key from output file
            try:
                contents, show_data = self._loader._get_file_contents(public_key_tmpfile)
                ret.append(to_text(contents).rstrip())
            except AnsibleParserError:
                raise AnsibleError("could not get file contents for %s" % (public_key_tmpfile))

            # Remove public_key_tmpfile and private_key_fifo
            os.unlink(public_key_tmpfile)
            os.unlink(private_key_fifo)
            os.rmdir(tmp_dir)

        return ret
