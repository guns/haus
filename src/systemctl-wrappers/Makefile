all:
	cc -Wall -ansi -pedantic systemctl-suspend.c -o systemctl-suspend

install: all
	install -d /usr/local/bin
	install -m 0755 systemctl-suspend /usr/local/bin
