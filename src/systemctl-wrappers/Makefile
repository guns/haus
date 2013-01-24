all:
	cc -Wall -ansi -pedantic systemctl-suspend.c -o systemctl-suspend

install: all
	install -d /usr/local/sbin
	install -m 0755 systemctl-suspend /usr/local/sbin
