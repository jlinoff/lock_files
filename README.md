lock_files
==========

Python command line tool to encrypt or decrypt files using AES encryption and a common password.

You can use it lock files before they are uploaded to storage services like DropBox or Google Drive.

The password can be stored in a safe file, specified on the command line or it can be manually entered each time the tool is run.

Here is how you would use this tool to encrypt a number of files using a local, secure file.

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

The tool checks each file to make sure that it is writeable before processing. If any files are not writeable, it means that they cannot be changed so the program aborts.

Notice that the program writes the encrypted data to the same file name by default. You can override this using the -u or --unique option as follows:

    $ lock_files -P ./password-file -r -v -e -u file1.txt
    $ ls file1.txt*
    file1.txt   file1.txt.enc

The -u option appends the .enc extension for files that are encrypted or the .dec extension for files that are decrypted. It is useful for guaranteeing that you do not overwrite the original files.

Finally, if you specify -v -v (very verbose), you will see the operations on each file.

Here is the on-line help:

    usage: lock_files.py [-h] [-d | -e] [-p PASSWORD_FILE | -P PASSWORD] [-r] [-u]
                         [-v] [-V]
                         [FILES [FILES ...]]
    
    description:
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
      operations on each file.
    
    positional arguments:
      FILES                 files to process

    optional arguments:
      -h, --help            show this help message and exit
      -d, --decrypt         decrypt
      -e, --encrypt         encrypt
      -p PASSWORD_FILE, --password-file PASSWORD_FILE
                            file that contains the password, default is to prompt
      -P PASSWORD, --password PASSWORD
                            password on the command line, not secure
      -r, --recurse         recurse when directories are encountered
      -u, --unique          use a unique file name for the output files
      -v, --verbose         level of verbosity
      -V, --version         show program's version number and exit

