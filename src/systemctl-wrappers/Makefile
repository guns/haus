all:
	cc -Wall -ansi -pedantic systemctl-wrapper.c -o systemctl-wrapper

clean:
	rm -f systemctl-wrapper

install: all
	install -d /usr/local/bin
	install -m 0755 systemctl-wrapper /usr/local/bin
