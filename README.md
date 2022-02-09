# Nix and Guix for Gentoo

Gentoo overlay for Nix and Guix functional package managers.

# Enabling the overlay

First, let's enable the overlay. We can either use the
eselect-repository method:

```bash
# Install eselect-repository if you don't already have it
emerge app-eselect/eselect-repository
# Fetch and output the list of overlays
eselect repository list
eselect repository enable nix-guix
```

or we can use the layman method:

```bash
# Add important USE flags for layman to your package.use directory:
echo "app-portage/layman sync-plugin-portage git" >> /etc/portage/package.use/layman
# Install layman if you don't already have it
emerge app-portage/layman
# Rebuild layman's repos.conf file:
layman-updater -R
# Add the Gentoo Haskell overlay:
layman -a nix-guix
```

Finally, we need to unmask the overlay (this does not apply if your system
is already running ~arch):

```bash
# Unmask ~testing versions for your arch:
echo "*/*::nix-guix" >> /etc/portage/package.accept_keywords
```

# Setup

## Nix

### Installation

The installation follows typical process of installing a
daemon in gentoo:

```bash
emerge nix
# on system systems:
systemctl enable nix-daemon && systemctl start nix-daemon
# on openrc systems:
rc-update add nix-daemon && /etc/init.d/nix-daemon start
```

Then relogin as your user to import profile variables and
pull in package definitions:

```
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
```

Next steps to try `nix` in action:

- <https://trofi.github.io/posts/196-nix-on-gentoo-howto.html>
- <https://nixos.org/manual/nixpkgs/stable/>

## Guix

### Installation

The installation follows typical process of installing a
daemon in gentoo:

```bash
emerge guix
# on system systems:
systemctl enable guix-daemon && systemctl start guix-daemon
# on openrc systems:
rc-update add guix-daemon && /etc/init.d/guix-daemon start
```

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

Next steps to try `guix` in action:

- <http://trofi.github.io/posts/197-guix-on-gentoo-howto.html>
- <https://guix.gnu.org/manual/>
