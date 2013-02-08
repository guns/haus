#include <unistd.h>

int main(void)
{
    char *const args[] = {"/usr/bin/systemctl", "suspend"};
    return execv(args[0], args);
}
