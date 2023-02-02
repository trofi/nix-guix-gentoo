#include <stdio.h>
#include <stdlib.h>

/* Not a real implementation.
 * Just a few stubs for llvm-libunwind to be complete enough for
 * busybox to be able to link against libc.a's printf().
 */

__attribute__((noreturn))
static void die(const char * func)
{
    fprintf(stderr, "%s not implemented.", func);
    fprintf(stderr, "Please report at https://github.com/trofi/nix-guix-gentoo/issues\n");
    exit(1);
}

int __unordtf2 (long double a, long double b)
{
    die(__func__);
}

int __letf2 (long double a, long double b)
{
    die(__func__);
}

long double __multf3 (long double a, long double b)
{
    die(__func__);
}

long double __addtf3 (long double a, long double b)
{
    die(__func__);
}
