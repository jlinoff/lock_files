define hdr
	@echo ""
	@echo "# ========================================================================"
	@printf "# %-70s #\n" $1
	@echo "# ========================================================================"
endef

define runit
	$(call hdr,$@)
	@rm -f $@.log
	((time ./test.sh '$@ ../lock_files.py' 2>&1) 2>&1) | tee -a $@.log | egrep '^test:|^FAILED|^PASSED'
endef

all: clean python2.7 python3.6

clean:
	$(call hdr,$@)
	rm -rf *~ *log *locked test.txt* tmp

python2.7: ; $(call runit,$@)
python3.5: ; $(call runit,$@)
python3.6: ; $(call runit,$@)
