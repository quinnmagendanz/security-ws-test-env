ASFLAGS := -m32
CFLAGS  := -m32 -g -std=c99 -Wall -Werror -D_GNU_SOURCE
LDFLAGS := -m32
LDLIBS  := -lcrypto
PROGS   := zookd \
           zookd-exstack \
           zookd-nxstack \
           zookd-withssp \
           shellcode.bin run-shellcode

ifeq ($(wildcard /usr/bin/execstack),)
  ifneq ($(wildcard /usr/sbin/execstack),)
    ifeq ($(filter /usr/sbin,$(subst :, ,$(PATH))),)
      PATH := $(PATH):/usr/sbin
    endif
  endif
endif

all: $(PROGS)
.PHONY: all

zookld zookd zookfs: %: %.o http.o
zookd-withssp: %: %.o http-withssp.o
run-shellcode: %: %.o

%-nxstack: %
	cp $< $@

%-exstack: %
	cp $< $@
	execstack -s $@

%.o: %.c
	$(CC) $< -c -o $@ $(CFLAGS) -fno-stack-protector

%-withssp.o: %.c
	$(CC) $< -c -o $@ $(CFLAGS)

%.bin: %.o
	objcopy -S -O binary -j .text $< $@



# For staff use only
staff-bin: zookd zookd-exstack zookd-nxstack
	tar cvzf bin.tar.gz $^

.PHONY: check-bugs
check-bugs:
	./check-bugs.py bugs.txt

.PHONY: check-crash
check-crash: bin.tar.gz exploit-2a.py exploit-2b.py shellcode.bin
	./check-bin.sh
	./check-ldcache.sh
	tar xf bin.tar.gz
	./check-part2.sh zookd-exstack ./exploit-2a.py
	./check-part2.sh zookd-nxstack ./exploit-2b.py

.PHONY: check-exstack
check-exstack: bin.tar.gz exploit-3.py shellcode.bin
	./check-bin.sh
	./check-ldcache.sh
	tar xf bin.tar.gz
	./check-part3.sh zookd-exstack ./exploit-3.py

.PHONY: check-libc
check-libc: bin.tar.gz exploit-4a.py exploit-4b.py shellcode.bin
	./check-bin.sh
	./check-ldcache.sh
	tar xf bin.tar.gz
	./check-part3.sh zookd-nxstack ./exploit-4a.py
	./check-part3.sh zookd-nxstack ./exploit-4b.py

.PHONY: check-crash-fixed
check-crash-fixed: clean $(PROGS) exploit-2a.py exploit-2b.py shellcode.bin
	./check-part2.sh zookd-exstack ./exploit-2a.py
	./check-part2.sh zookd-exstack ./exploit-2b.py

.PHONY: check-exstack-fixed
check-exstack-fixed: clean $(PROGS) exploit-3.py shellcode.bin
	./check-part3.sh zookd-exstack ./exploit-3.py

.PHONY: check-libc-fixed
check-libc-fixed: clean $(PROGS) exploit-4a.py exploit-4b.py shellcode.bin
	./check-part3.sh zookd-nxstack ./exploit-4a.py
	./check-part3.sh zookd-nxstack ./exploit-4b.py

.PHONY: check-fixed
check-fixed: check-crash-fixed check-exstack-fixed check-libc-fixed

.PHONY: check-zoobar
check-zoobar:
	./check_zoobar.py

.PHONY: check
check: check-zoobar check-bugs check-crash check-exstack check-libc


.PHONY: fix-flask
fix-flask: fix-flask.sh
	./fix-flask.sh

.PHONY: clean
clean:
	rm -f *.o *.pyc *.bin $(PROGS)


lab%-handin.tar.gz: clean
	tar cf - `find . -type f | grep -v '^\.*$$' | grep -v '/CVS/' | grep -v '/\.svn/' | grep -v '/\.git/' | grep -v 'lab[0-9].*\.tar\.gz' | grep -v '/submit.token$$' | grep -v libz3str.so` | gzip > $@

.PHONY: prepare-submit
prepare-submit: lab1-handin.tar.gz

.PHONY: prepare-submit-a
prepare-submit-a: lab1a-handin.tar.gz

.PHONY: prepare-submit-b
prepare-submit-b: lab1b-handin.tar.gz

.PHONY: submit-a
submit-a: lab1a-handin.tar.gz
	./submit.py $<

.PHONY: submit-b
submit-b: lab1b-handin.tar.gz
	./submit.py $<

.PHONY: submit
submit: lab1-handin.tar.gz
	./submit.py $<

.PRECIOUS: lab1-handin.tar.gz
