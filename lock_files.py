#!/usr/bin/env python
'''
Encrypt and decrypt files using AES encryption and a common
password. You can use it lock files before they are uploaded to
storage services like DropBox or Google Drive.

The password can be stored in a safe file, specified on the command
line or it can be manually entered each time the tool is run.

Here is how you would use this tool to encrypt a number of files
using a local, secure file.

   $ cat >password-file
   thisismysecretpassword
   EOF
   $ chmod 0600 password-file
   $ lock_files -P ./password-file -r -v -e file1.txt file2.txt dir1 dir2

Here is how you would use this tool to decrypt a number of files.

   $ lock_files -P ./password-file -r -v -d file1.txt file2.txt dir1 dir2

Here is how you would use this tool to decrypt a file, execute a
program and then re-encrypt it when the program exits.

   $ lock_files -P ./password --decrypt file1.txt
   $ emacs file1.txt
   $ lock_files -P ./password --encrypt file1.txt

The tool checks each file to make sure that it is writeable before
processing. If any files are not writeable, it means that they cannot
be changed so the program aborts.

Notice that the program writes the encrypted data to the same file
name by default. You can override this using the -u or --unique option
as follows:

   $ lock_files -P ./password-file -r -v -e -u file1.txt
   $ ls file1.txt*
   file1.txt   file1.txt.enc

The -u option appends the .enc extension for files that are encrypted
or the .dec extension for files that are decrypted. It is useful for
guaranteeing that you do not overwrite the original files.

Finally, if you specify -v -v (very verbose), you will see the
operations on each file.'''
import argparse
import inspect
import getpass
import os
import sys
import base64
from Crypto import Random
from Crypto.Cipher import AES


# CITATION: http://stackoverflow.com/questions/12524994/encrypt-decrypt-using-pycrypto-aes-256
class AESCipher:
    def __init__(self, key):
        self.bs = 32
        if len(key) >= 32:
            self.key = key[:32]
        else:
            self.key = self._pad(key)

    def encrypt(self, raw):
        raw = self._pad(raw)
        iv = Random.new().read(AES.block_size)
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return base64.b64encode(iv + cipher.encrypt(raw))

    def decrypt(self, enc):
        enc = base64.b64decode(enc)
        iv = enc[:AES.block_size]
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return self._unpad(cipher.decrypt(enc[AES.block_size:]))

    def _pad(self, s):
        return s + (self.bs - len(s) % self.bs) * chr(self.bs - len(s) % self.bs)

    def _unpad(self, s):
        return s[:-ord(s[len(s)-1:])]


def _msg(msg, prefix, level=2, ofp=sys.stdout):
    '''
    Display a simple information message with context information.
    '''
    frame = inspect.stack()[level]
    file_name = os.path.basename(frame[1])
    lineno = frame[2]
    ofp.write('%s:%s:%d %s\n' % (prefix, file_name, lineno, msg))


def info(msg, level=1, ofp=sys.stdout):
    '''
    Display a simple information message with context information.
    '''
    _msg(prefix='INFO', msg=msg, level=level+1, ofp=ofp)


def infov(opts, msg, level=1, ofp=sys.stdout):
    '''
    Display a simple information message with context information.
    '''
    if opts.verbose:
        _msg(prefix='INFO', msg=msg, level=level+1, ofp=ofp)


def infov2(opts, msg, level=1, ofp=sys.stdout):
    '''
    Display a simple information message with context information.
    '''
    if opts.verbose > 1:
        _msg(prefix='INFO', msg=msg, level=level+1, ofp=ofp)


def err(msg, level=1, ofp=sys.stdout):
    '''
    Display error message with context information and exit.
    '''
    _msg(prefix='ERROR', msg=msg, level=level+1, ofp=ofp)
    sys.exit(1)


def errn(msg, level=1, ofp=sys.stdout):
    '''
    Display error message with context information but do not exit.
    '''
    _msg(prefix='ERROR', msg=msg, level=level+1, ofp=ofp)


def warn(msg, level=1, ofp=sys.stdout):
    '''
    Display error message with context information but do not exit.
    '''
    _msg(prefix='WARNING', msg=msg, level=level+1, ofp=ofp)


def crypt(opts, password, files):
    '''
    Encrypt or decrypt the files.
    '''
    encrypt = True
    mode = 'encrypt'
    if opts.decrypt is True:
        encrypt = False
        mode = 'decrypt'
    aes = AESCipher(password)
    ext = ''
    if opts.unique:
        ext = '.enc' if encrypt else '.dec'

    for path in files:
        ifp = open(path, 'rb')
        data = ifp.read()
        ifp.close()

        opath = path + ext
        infov2(opts, '%s %s' % (mode, opath))
        try:
            if encrypt:
                modified = aes.encrypt(data)
            else:
                modified = aes.decrypt(data)

            ofp = open(opath, 'wb')
            ofp.write(modified)
            ofp.close()

        except ValueError:
            warn('%s operation failed, skipping %s' %(mode, opath))

    infov(opts, '%d files %sed' % (len(files), mode))


def load_files(opts):
    '''
    Load the specified files.
    '''

    def check_file_access(path):
        '''
        Check the file access.
        '''
        if os.access(path, os.R_OK) is False:
            errn('cannot read file: ' + path)
            return 1
        if os.access(path, os.W_OK) is False:
            errn('cannot write file: ' + path)
            return 1
        return 0

    nerrs = 0
    files = []
    for entry in opts.FILES:
        if os.path.isfile(entry):
            infov2(opts, 'loading file ' + entry)
            files.append(entry)
            nerrs += check_file_access(entry)
        elif os.path.isdir(entry):
            if opts.recurse:
                for wroot, wdirs, wfiles in os.walk(entry):
                    for wfile in sorted(wfiles, key=str.lower):
                        if wfile in ['.', '..']:
                            continue
                        wpath = os.path.join(wroot, wfile)
                        infov2(opts, 'loading file ' + wpath)
                        files.append(wpath)
                        nerrs += check_file_access(wpath)
            else:
                infov2(opts, 'skipping dir ' + entry)
        else:
            infov2(opts, 'skipping entry ' + entry)

    infov(opts, '%d files loaded' % (len(files)))
    if nerrs:
        err('%d access errors found, cannot proceed' % (nerrs))

    return files


def get_password(opts):
    '''
    Get the password.
    '''
    # User specified it on the command line. Not safe but useful for testing
    # and for scripts.
    if opts.password:
        return opts.password

    # User specified the password in a file. It should be 0600.
    if opts.password_file:
        if os.path.exists(opts.password_file):
            err("password file doesn't exist: %s" % (opts.password_file))
        password = None
        ifp = open(opts.password_file, 'r')
        for line in ifp.readlines():
            line.strip()  # leading and trailing white space not allowed
            if len(line) == 0:
                continue  # skip blank lines
            if line[0] == '#':
                continue  # skip comments
            password = line
            break
        ifp.close()
        if password is None:
            err('password was not found in file ' + opts.password_file)
        return password

    # User did not specify a password, prompt.
    password = getpass.getpass('Password: ')
    password2 = getpass.getpass('Re-enter password: ')
    if password != password2:
        err('passwords did not match!')
    return password


def getopts():
    '''
    Get the command line options.
    '''
    this = os.path.basename(sys.argv[0])
    description = ('description:%s' % '\n  '.join(__doc__.split('\n')))
    rawd = argparse.RawDescriptionHelpFormatter
    parser = argparse.ArgumentParser(formatter_class=rawd,
                                     description=description,
                                     prefix_chars='-')

    group1 = parser.add_mutually_exclusive_group()
    group1.add_argument('-d', '--decrypt',
                        action='store_true',
                        help='decrypt')
    
    group1.add_argument('-e', '--encrypt',
                        action='store_true',
                        help='encrypt')

    group2 = parser.add_mutually_exclusive_group()
    group2.add_argument('-p', '--password-file',
                        action='store',
                        type=str,
                        help='file that contains the password, default is to prompt')

    group2.add_argument('-P', '--password',
                        action='store',
                        type=str,
                        help='password on the command line, not secure')

    parser.add_argument('-r', '--recurse',
                        action='store_true',
                        help='recurse when directories are encountered')

    parser.add_argument('-u', '--unique',
                        action='store_true',
                        help='use a unique file name for the output files')

    parser.add_argument('-v', '--verbose',
                        action='count',
                        help='level of verbosity')

    # Display the version number and exit.
    parser.add_argument('-V', '--version',
                        action='version',
                        version='%(prog)s - v1.0')

    # Positional arguments at the end.
    parser.add_argument('FILES',
                        nargs="*",
                        help='files to process')

    opts = parser.parse_args()
    return opts


def main():
    '''
    main
    '''
    opts = getopts()
    password = get_password(opts)
    files = load_files(opts)
    crypt(opts, password, files)


if __name__ == '__main__':
    main()
