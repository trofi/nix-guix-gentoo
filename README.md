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
`~/.profile` / `~/.bash_profile` / `~/.zprofile` or equivalent.

To install a `GNU hello` package to test out Guix execute:

```bash
guix package -i hello
```

If you plan to use `guix pull` (and you probably are) you'll need to add
it's `PATH` to your shell as well by following `guix pull`'s
[suggestion](https://guix.gnu.org/manual/en/html_node/Invoking-guix-pull.html):

```bash
export PATH="$HOME/.config/guix/current/bin:$PATH"
export INFOPATH="$HOME/.config/guix/current/share/info:$INFOPATH"
```
