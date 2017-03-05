lock_files
==========

This is version 2.x of the python command line tool to encrypt or decrypt files using AES encryption and a common password. This version works in python2 and python3.

## Overview
You can use it lock files before they are uploaded to storage services like DropBox or Google Drive.

The password can be stored in a safe file, specified on the command line or it can be manually entered each time the tool is run.

Here is how you would use this tool to encrypt a number of files _in place_ using a local, secure file. The term _in place_ means
not appending the `.locked` suffix to each file name that was locked (e.g. encrypted). _In place_ is not secure because data
will be lost if the disk fills up during a write operation and it is not able to complete.

    $ cat >password-file
    thisismysecretpassword
    EOF
    $ chmod 0600 password-file
    $ lock_files.py -p ./password-file -i -l file1.txt file2.txt dir1 dir2

Here is how you would use this tool to unloock (e.g. decrypt) a number of _in place_ locked files.
Note that at this point `file1.txt` is actually encrypted.

    $ lock_files.py -p ./password-file -i -u file1.txt file2.txt dir1 dir2

Here is how you would use this tool to decrypt a file, execute a
program and then re-encrypt it when the program exits.

    $ lock_files.py -p ./password -i -u file1.txt
    $ emacs file1.txt
    $ lock_files.py -p ./password -i -l file1.txt

The tool checks each file to make sure that it is writeable before processing. If any files are not writeable,
it means that they cannot be changed so the program aborts unless you specified the continue `-c` option.

Normal operation writes the encrypted to a locked file like this.
You can override this using the -u or --unique option as follows:

    $ lock_files.py -p ./password-file -l file1.txt
    $ ls file1.txt*
    file1.txt.locked
    $ lock_files.py  -p ./password-file -u file1.txt
    $ ls file1.txt*
    file1.txt

If you specify -v -v (very verbose), you will see the operations on each file.

## Download and Test
Here is how you download and test it. I have multiple versions of python installed so I set the the first argument
to the test script. If you only have a single version of python, the you do not specify an argument. It assumes the 
python that is in your path.

```bash
$ git clone https://github.com/jlinoff/lock_files.git
$ cd lock_files/test

$ # Use the default version of python.
$ ./test.sh

$ # Use a specific version of python 2.
$ ./test.sh 'python2.7 ./test.sh'
[output snipped]

$ # Use a specific version of python 3.
$ ./test.sh 'python3.6 ./test.sh'
[output snipped]
```

## Help
Here is the on-line help. It describes all of the options and provides examples.

```bash
$ lock_files.py -h
USAGE:
  lock_files.py [OPTIONS] [<FILES_OR_DIRS>]+

DESCRIPTION:
  Encrypt and decrypt files using AES encryption and a common
  password. You can use it lock files before they are uploaded to
  storage services like DropBox or Google Drive.
  
  The password can be stored in a safe file, specified on the command
  line or it can be manually entered each time the tool is run.
  
  Here is how you would use this tool to encrypt a number of files using
  a local, secure file. You can optionally specify the --lock switch but
  since it is the default, it is not necessary.
  
     $ lock_files.py file1.txt file2.txt dir1 dir2
     Password: secret
     Re-enter password: secret
  
  When the lock command is finished all of files will be locked (encrypted,
  with a ".locked" extension).
  
  You can lock the same files multiple times with different
  passwords. Each time lock_files.py is run in lock mode, another
  ".locked" extension is appended. Each time it is run in unlock mode, a
  ".locked" extension is removed. Unlock mode is enabled by specifying
  the --unlock option.
  
  Of course, entering the password manually each time can be a challenge.
  It is normally easier to create a read-only file that can be re-used.
  Here is how you would do that.
  
     $ cat >password-file
     thisismysecretpassword
     EOF
     $ chmod 0600 password-file
  
  You can now use the password file like this to lock and unlock a file.
  
     $ lock_files.py -p password-file file1.txt
     $ lock_files.py -p password-file --unlock file1.txt.locked
  
  In decrypt mode the tool walks through the specified files and
  directories looking for files with the .locked extension and unlocks
  (decrypts) them.
  
  Here is how you would use this tool to decrypt a file, execute a
  program and then re-encrypt it when the program exits.
  
     $ # the unlock operation removes the .locked extension
     $ lock_files -p ./password --unlock file1.txt.locked
     $ edit file1.txt
     $ lock_files -p ./password file1.txt
  
  The tool checks each file to make sure that it is writeable before
  processing. If any files is not writeable, the program reports an
  error and exits unless you specify --cont in which case it
  reports a warning that the file will be ignored and continues.
  
  If you want to change a file in place you can use --inplace mode.
  See the documentation for that option to get more information.

POSITIONAL ARGUMENTS:
  FILES                 files to process

OPTIONAL ARGUMENTS:
  -h, --help            Show this help message and exit.
                         
  -c, --cont            Continue if a single file lock/unlock fails.
                        Normally if the program tries to modify a fail and that modification
                        fails, an error is reported and the programs stops. This option causes
                        that event to be treated as a warning so the program continues.
                         
  -d, --decrypt         Unlock/decrypt files.
                        This option is deprecated.
                        It is the same as --unlock.
                         
  -e, --encrypt         Lock/encrypt files.
                        This option is deprecated.
                        This is the same as --lock and is the default.
                         
  -i, --inplace         In place mode.
                        Overwrite files in place.
                        
                        It is the same as specifying:
                           -o -s ''
                        
                        This is a dangerous because a disk full operation can cause data to be
                        lost when a write fails. This allows you to duplicate the behavior of
                        the previous version.
                         
  -l, --lock            Lock files.
                        Files are locked and the ".locked" extension is appended unless
                        the --suffix option is specified.
                         
  -o, --overwrite       Overwrite files that already exist.
                        This can be used in conjunction disable file existence checks.
                        It is used by the --inplace mode.
                         
  -n, --no-recurse      Do not automatically recurse into subdirectories.
                         
  -p PASSWORD_FILE, --password-file PASSWORD_FILE
                        file that contains the password.
                        The default behavior is to prompt for the password.
                         
  -P PASSWORD, --password PASSWORD
                        Specify the password on the command line.
                        This is not secure because it is visible in the command history.
                         
  -s EXTENSION, --suffix EXTENSION
                        Specify the extension used for locked files.
                        Default: .locked
                         
  -u, --unlock          Unlock files.
                        Files with the ".locked" extension are unlocked.
                        If the --suffix option is specified, that extension is used instead of ".locked".
                         
  -v, --verbose         Increase the level of verbosity.
                        A single -v generates a summary report.
                        Two or more -v options show all of the files being processed.
                         
  -V, --version         Show program's version number and exit.
                         

EXAMPLES:
   # Example 1: help
   $ lock_files.py -h

   # Example 2: lock/unlock a single file
   $ lock_files.py -P 'secret' file.txt
   $ ls file.txt*
   file.txt.locked
   $ lock_files.py -P 'secret' --unlock file.txt
   $ ls -1 file.txt*
   file.txt

   # Example 3: lock/unlock a set of directories
   $ lock_files.py -P 'secret' project1 project2
   $ find project1 project2 --type f -name '*.locked'
   <output snipped>
   $ lock_files.py -P 'secret' --unlock project1 project2

   # Example 4: lock/unlock using a custom extension
   $ lock_files.py -P 'secret' -s .EncRypt file.txt
   $ ls file.txt*
   file.txt.EncRypt
   $ lock_files.py -P 'secret' -s .EncRypt --unlock file.txt

   # Example 5: lock/unlock a file in place (using the same name)
   #            The file name does not change but the content.
   #            It is compatible with the default mode of operation in
   #            previous releases.
   #            This mode of operation is not recommended because
   #            data will be lost if the disk fills up during a write.
   $ lock_files.py -P 'secret' -i -l file.txt
   $ ls file.txt*
   file.txt
   $ lock_files.py -P 'secret' -i -u file.txt
   $ ls file.txt*
   file.txt

   # Example 6: use a password file.
   $ echo 'secret' >pass.txt
   $ chmod 0600 pass.txt
   $ lock_files.py -p pass.txt -l file.txt
   $ lock_files.py -p pass.txt -u file.txt.locked

COPYRIGHT:
   Copyright (c) 2015 Joe Linoff, all rights reserved

LICENSE:
   MIT Open Source

PROJECT:
   https://github.com/jlinoff/lock_files
```
