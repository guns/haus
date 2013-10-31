#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#define PROGNAME "systemctl-wrapper"
#define SUSPEND  "suspend"
#define REBOOT   "reboot"
#define POWEROFF "poweroff"

void die()
{
	fprintf(stderr, "Usage: %s %s|%s|%s\n", PROGNAME, SUSPEND, REBOOT, POWEROFF);
	exit(1);
}

int main(int argc, char const **argv)
{
	char *args[2];

	if (argc != 2)
		die();

	args[0] = "/usr/bin/systemctl";

	if (strcmp(argv[1], SUSPEND) == 0)
		args[1] = SUSPEND;
	else if (strcmp(argv[1], REBOOT) == 0)
		args[1] = REBOOT,
		args[2] = "--force",
		args[3] = "-i"; /* --ignore-inhibitors */
	else if (strcmp(argv[1], POWEROFF) == 0)
		args[1] = POWEROFF,
		args[2] = "--force",
		args[3] = "-i"; /* --ignore-inhibitors */
	else
		die();

	return execv(args[0], args);
}
