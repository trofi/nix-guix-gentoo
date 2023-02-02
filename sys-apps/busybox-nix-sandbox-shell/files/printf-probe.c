#include <stdio.h>

/* Trivial test to validate linkage against libc's printf(). */

int main(int argc, char * argv[]) {
    fprintf(stderr, "args: %d", argc);
    return 0;
}
