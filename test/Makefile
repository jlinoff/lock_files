define hdr
	@echo ""
	@echo "# ========================================================================"
	@printf "# %-70s #\n" $1
	@echo "# ========================================================================"
endef

all: p27 p36

clean:
	rm -rf *~ *log *locked test.txt* tmp

p27:
	$(call hdr,"Python 2.7")
	@rm -f $@.log
	./test.sh 'python2.7 ../lock_files.py' 2>&1 | tee -a $@.log | egrep '^test:|^FAILED|^PASSED'

p36:
	$(call hdr,"Python 2.7")
	@rm -f $@.log
	./test.sh 'python3.6 ../lock_files.py' 2>&1 | tee -a $@.log | egrep '^test:|^FAILED|^PASSED'
