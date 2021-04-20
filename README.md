# Nix and Guix for Gentoo

Gentoo overlay for Nix and Guix functional package managers.


# Setup


## Guix


### First run

Upon first package installation Guix will create `~/.guix-profile` symlink to
`/var/guix/profiles/per-user/${USER}` (where `${USER}` is your user account
name in current shell).

In order to allow Guix to set all variables correctly execute those commands:

```bash
export GUIX_PROFILE="${HOME}/.guix-profile"
export GUIX_LOCPATH="${GUIX_PROFILE}/lib/locale"
source "${GUIX_PROFILE}/etc/profile"
```

The best way is to add the commands to your `${SHELL}` profile file:
.profile / .bash_profile / .zprofile

To install a `GNU hello` package to test out Guix execute:

```bash
guix package -i hello
```
