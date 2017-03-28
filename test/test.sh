#!/bin/bash
#
# Run all of the tests.
#
# If a failure occurs, find the failed messages and look at the
# associated line numbers.
#
# If, like me, you use different versions of python, you
# select them as follows:
#    ./test.sh 'python2.7 ../lock_files.py'
#    ./test.sh 'python3.6 ../lock_files.py'
#
# Note that file1.txt and file2.txt are copied to intermediate
# files throughout the tests. This is so that test data is not
# destroyed if there is a problem.

# ================================================================
# Functions
# ================================================================
# Print an info message with context (caller line number)
function info() {
    local Msg="$*"
    echo -e "INFO:${BASH_LINENO[0]}: $Msg"
}

function Test() {
    local Memo="$1"
    shift
    local Cmd="$*"
    local LineNum=${BASH_LINENO[0]}
    (( Total++ ))
    local Tid=$(printf '%03d' $Total)
    echo
    echo "INFO:${LineNum}: cmd.run=$Cmd"
    printf "test:%s:%s:cmd " $Tid "$LineNum" "$Memo"
    echo "$Cmd"
    eval "$Cmd"
    local st=$?
    echo "INFO:${LineNum}: cmd.status=$st"
    if (( st )) ; then
        echo "ERROR:${LineNum}: command failed"
        (( Failed++ ))
        printf "test:%s:%s:failed %s\n" $Tid "$LineNum" "$Memo"
        Done
    else
        (( Passed++ ))
        printf "test:%s:%s:passed %s\n" $Tid "$LineNum" "$Memo"
    fi
}

function Runcmd() {
    local Cmd="$*"
    local LineNum=${BASH_LINENO[0]}
    echo
    echo "INFO:${LineNum}: cmd.run=$Cmd"
    eval "$Cmd"
    local st=$?
    echo "INFO:${LineNum}: cmd.status=$st"
    if (( st )) ; then
        echo "ERROR:${LineNum}: command failed"
        exit 1
    fi
}

function Done() {
    echo
    printf "test:total:passed  %3d\n" $Passed
    printf "test:total:failed  %3d\n" $Failed
    printf "test:total:summary %3d\n" $Total

    echo
    if (( Failed )) ; then
        echo "FAILED"
    else
        echo "PASSED"
    fi
    exit $Failed
}

# ================================================================
# Main
# ================================================================
Passed=0
Failed=0
Total=0
Prog=${1:-"../lock_files.py"}
info "Prog=$Prog"
rm -f test*.txt*

# Test simple lock.
Runcmd cp file1.txt test.txt
Test 'lock-run' $Prog -P secret --lock test.txt
Runcmd cat -n test.txt.locked
Test 'lock-exists' '[' -e 'test.txt.locked' ']'
Test 'unlock-run' $Prog -P secret --unlock test.txt.locked
Test 'unlock-exists' '[' -e 'test.txt' ']'
Test 'diff-test' diff file1.txt test.txt

# Test simple lock with a password file.
LC_CTYPE=C tr -dc A-Za-z0-9_\- < /dev/urandom | head -c 32 | xargs > testpass.txt
Runcmd cp file1.txt test.txt
Test 'lock-run' $Prog -p testpass.txt --lock test.txt
Runcmd cat -n test.txt.locked
Test 'lock-exists' '[' -e 'test.txt.locked' ']'
Test 'unlock-run' $Prog -p testpass.txt --unlock test.txt.locked
Test 'unlock-exists' '[' -e 'test.txt' ']'
Test 'diff-test' diff file1.txt test.txt

# Test lock with line lock width (--wll set).
Runcmd cp file1.txt test.txt
Test 'lock-run' $Prog -P secret -w 64 --lock test.txt
Runcmd cat -n test.txt.locked
Test 'lock-exists' '[' -e 'test.txt.locked' ']'
Test 'unlock-run' $Prog -P secret --unlock test.txt.locked
Test 'unlock-exists' '[' -e 'test.txt' ']'
Test 'diff-test' diff file1.txt test.txt

# Now try file globbing and locking.
Runcmd cp file1.txt test1.txt
Runcmd cp file2.txt test2.txt
Test 'lock-run' $Prog -P secret --lock test[12].txt
Test 'lock-exists' '[' -e 'test1.txt.locked' ']'
Test 'lock-exists' '[' -e 'test2.txt.locked' ']'
Test 'unlock-run' $Prog -P secret --unlock test[12]*.locked
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Test 'unlock-exists' '[' -e 'test2.txt' ']'
Test 'diff-test' diff file1.txt test1.txt
Test 'diff-test' diff file2.txt test2.txt

# Try a different locked suffix.
Runcmd cp file1.txt test1.txt
Test 'lock-run' $Prog -P secret -s '.FOO' --lock test1.txt
Test 'lock-exists' '[' -e 'test1.txt.FOO' ']'
Test 'unlock-run' $Prog -P secret -s '.FOO' --unlock test1.txt.FOO
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Test 'diff-test' diff file1.txt test1.txt

# Test simple lock using short forms.
Runcmd cp file1.txt test1.txt
Test 'lock-run' $Prog -P secret -l test1.txt
Test 'lock-exists' '[' -e 'test1.txt.locked' ']'
Test 'unlock-run' $Prog -P secret -u test1.txt.locked
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Test 'diff-test' diff file1.txt test1.txt

# Test simple lock using default and forms.
Runcmd cp file1.txt test1.txt
Test 'lock-run' $Prog -P secret test1.txt
Test 'lock-exists' '[' -e 'test1.txt.locked' ']'
Test 'unlock-run' $Prog -P secret -u test1.txt.locked
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Test 'diff-test' diff file1.txt test1.txt

# Test directories - recurse.
# setup
Runcmd rm -rf tmp
Runcmd mkdir tmp
Runcmd cp file1.txt tmp/
Runcmd mkdir tmp/tmp
Runcmd cp file1.txt tmp/tmp
Runcmd cp file2.txt tmp/tmp
Runcmd tree tmp

Test 'tmp-setup' '[' -e 'tmp/file1.txt' ']'
Test 'tmp-setup' '[' -e 'tmp/tmp/file1.txt' ']'
Test 'tmp-setup' '[' -e 'tmp/tmp/file2.txt' ']'
Test 'lock-run' $Prog -P secret -v -v -r -l tmp
Test 'tmp-setup' '[' -e 'tmp/file1.txt.locked' ']'
Test 'tmp-setup' '[' -e 'tmp/tmp/file1.txt.locked' ']'
Test 'tmp-setup' '[' -e 'tmp/tmp/file2.txt.locked' ']'
Runcmd tree tmp
Test 'unlock-run' $Prog -P secret -v -v -r -u tmp
Test 'tmp-final' '[' -e 'tmp/file1.txt' ']'
Test 'tmp-final' '[' -e 'tmp/tmp/file1.txt' ']'
Test 'tmp-final' '[' -e 'tmp/tmp/file2.txt' ']'
Test 'diff-test' diff tmp/file1.txt file1.txt
Test 'diff-test' diff tmp/tmp/file1.txt file1.txt
Test 'diff-test' diff tmp/tmp/file2.txt file2.txt
Runcmd tree tmp
Runcmd rm -rf tmp

# Test directories - recurse.
# setup
Runcmd rm -rf tmp
Runcmd mkdir tmp
Runcmd cp file1.txt tmp/
Runcmd mkdir tmp/tmp
Runcmd cp file1.txt tmp/tmp
Runcmd tree tmp

Test 'tmp-setup' '[' -e 'tmp/file1.txt' ']'
Test 'tmp-setup' '[' -e 'tmp/tmp/file1.txt' ']'
Test 'lock-run' $Prog -P secret -v -v tmp
Test 'tmp-setup' '[' -e 'tmp/file1.txt.locked' ']'
Test 'tmp-setup' '[' '!' -e 'tmp/tmp/file1.txt.locked' ']'
Runcmd tree tmp
Test 'unlock-run' $Prog -P secret -v -v --unlock tmp
Test 'tmp-final' '[' -e 'tmp/file1.txt' ']'
Test 'tmp-final' '[' -e 'tmp/tmp/file1.txt' ']'
Runcmd tree tmp
Runcmd rm -rf tmp

# test continue with warning: -W, --warn
Runcmd cp file1.txt test1.txt
Runcmd cp file2.txt test2.txt
Test 'lock-run' $Prog -P secret -v -v --lock -W test1.txt testXXX.txt test2.txt
Test 'lock-exists' '[' -e 'test1.txt.locked' ']'
Test 'lock-exists' '[' -e 'test2.txt.locked' ']'
Test 'unlock-run' $Prog -P secret -v -v --unlock -W test1.txt.locked testXXX.txt.locked test2.txt.locked
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Test 'unlock-exists' '[' -e 'test2.txt' ']'
Test 'diff-test' diff file1.txt test1.txt
Test 'diff-test' diff file2.txt test2.txt

# test locked extension.
Runcmd cp file1.txt test1.txt.locked
Test 'lock-run' $Prog -P secret -v -v --lock test1.txt.locked
Test 'lock-exists' '[' -e 'test1.txt.locked.locked' ']'
Test 'unlock-run' $Prog -P secret -v -v --unlock -W test1.txt.locked.locked
Test 'unlock-exists' '[' -e 'test1.txt.locked' ']'
Test 'diff-test' diff file1.txt test1.txt.locked
Runcmd rm -f test1.txt.locked

# Test overwrite functionality.
# -s '' -o
Runcmd cp file1.txt test1.txt
Runcmd wc test1.txt
Runcmd sum test1.txt
Test 'lock-run' $Prog -P secret -v -v --lock -o -s '' test1.txt
Test 'lock-exists' '[' '!' -e 'test1.txt.locked' ']'
Test 'lock-exists' '[' -e 'test1.txt' ']'
Runcmd wc test1.txt
Runcmd sum test1.txt
Test 'unlock-run' $Prog -P secret -v -v --unlock -o -s '' test1.txt
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Runcmd wc test1.txt
Runcmd sum test1.txt
Test 'diff-test' diff file1.txt test1.txt

# Test inplace mode.
Runcmd cp file1.txt test1.txt
Runcmd wc test1.txt
Runcmd sum test1.txt
Test 'lock-run' $Prog -P secret -v -v --lock -i test1.txt
Test 'lock-exists' '[' '!' -e 'test1.txt.locked' ']'
Test 'lock-exists' '[' -e 'test1.txt' ']'
Runcmd wc test1.txt
Runcmd sum test1.txt
Test 'unlock-run' $Prog -P secret -v -v --unlock -i test1.txt
Test 'unlock-exists' '[' -e 'test1.txt' ']'
Runcmd wc test1.txt
Runcmd sum test1.txt
Test 'diff-test' diff file1.txt test1.txt

# Test openssl compatibility.
info 'test openssl encrypt, lock_files decrypt'
tid=${LINENO}
Runcmd rm -f test.txt test.txt.locked
Runcmd cp file1.txt test.txt
Test 'openssl-enc' openssl enc -aes-256-cbc -e -a -salt -pass pass:secret -in test.txt -out test.txt.locked
Test 'unlock-run' $Prog -c -W -P secret -u test.txt.locked
Test 'diff-test' diff file1.txt test1.txt

info 'test lock_files encrypt, openssl decrypt'
Runcmd rm -f test.txt test.txt.locked
Runcmd cp file1.txt test.txt
Test 'lock-run' $Prog -c -W -P secret -l test.txt
Test 'openssl-dec' openssl enc -aes-256-cbc -d -a -salt -pass pass:secret -in test.txt.locked -out test.txt
Test 'diff-test' diff file1.txt test1.txt

# Test different lengths to verify padding.
for(( i=1; i<=33; i++ )) ; do
    str=""
    for(( j=1; j<=i; j++ )) ; do
        (( k = j % 10 ))
        str+="$k"
    done
    echo "$str" >test1.txt
    Test "lock-run-$i" $Prog -P secret -v -v --lock -i test1.txt
    Test 'lock-exists' '[' -e 'test1.txt' ']'
    Test  "unlock-run-$i" $Prog -P secret -v -v --unlock -i test1.txt
done

# Test different processing of 200 files to analyze thread performance.
info 'setup for jobs test'
Runcmd rm -rf tmp
Runcmd mkdir tmp
for(( i=1; i<=200; i++ )) ; do
    fn=$(echo "$i" | awk '{printf("tmp/test%03d.txt", $1)}')
    Runcmd cp file1.txt "$fn"
done
info 'setup done'

Test 'job-test001-check' '[' -e 'tmp/test001.txt' ']'
Test 'job-test100-check' '[' -e 'tmp/test100.txt' ']'
Test 'job-test200-check' '[' -e 'tmp/test200.txt' ']'
Test 'lock-run-200' time $Prog -P secret -v -v --lock tmp
Test 'unlock-run-200' time $Prog -P secret -v -v --unlock tmp

# performance analysis (10 threads)
# Use big files.
info 'setup for jobs performance analysis'
Runcmd rm -rf tmp
Runcmd mkdir tmp
for(( i=1; i<=200; i++ )) ; do
    fn=$(echo "$i" | awk '{printf("tmp/test%03d.txt", $1)}')
    if (( i == 1 )) ; then
        # Create a big file for the first one.
        for(( j=1; j<=2000; j++)) ; do
            Runcmd cat file1.txt '>>' "$fn"
        done
    else
        Runcmd cp tmp/test001.txt $fn
    fi
done
info 'setup done'

Test 'job-test001-check' '[' -e 'tmp/test001.txt' ']'
Test 'job-test100-check' '[' -e 'tmp/test100.txt' ']'
Test 'job-test200-check' '[' -e 'tmp/test200.txt' ']'
Test 'lock-run-200-th10' time $Prog -P secret -v -j 10 --lock tmp
Test 'unlock-run-200-th10' time $Prog -P secret -v -j 10 --unlock tmp

# performance analysis (1 thread)
Test 'lock-run-200-th1' time $Prog -P secret -v -j 1 --lock tmp
Test 'unlock-run-200-th1' time $Prog -P secret -v -j 1 --unlock tmp

Runcmd rm -rf test*.txt* tmp *~

Done
