# Nix and Guix for Gentoo

Gentoo overlay for [Nix](https://nixos.org/) and
[GNU Guix](https://guix.gnu.org/) functional package managers.

# Enabling the overlay

First, let's enable the overlay. We can either use the
`eselect-repository` method:

```sh
# Install eselect-repository if you don't already have it
emerge app-eselect/eselect-repository
# Fetch and output the list of overlays
eselect repository list
eselect repository enable nix-guix
emaint sync -r nix-guix
```

or we can use the layman method:

```sh
# Add important USE flags for layman to your package.use directory:
echo "app-portage/layman sync-plugin-portage git" >> /etc/portage/package.use/layman
# Install layman if you don't already have it
emerge app-portage/layman
# Rebuild layman's repos.conf file:
layman-updater -R
# Add the ::nix-guix overlay:
layman -a nix-guix
```

Finally, we need to unmask the overlay (this does not apply if your system
is already running ~arch):

```sh
# Unmask ~testing versions for your arch:
echo "*/*::nix-guix" >> /etc/portage/package.accept_keywords
```

# Setup

## Nix

### Installation

The installation follows typical process of installing a
daemon in `gentoo`:

```sh
emerge nix
# on systemd systems:
systemctl enable nix-daemon && systemctl start nix-daemon
# on openrc systems:
rc-update add nix-daemon && /etc/init.d/nix-daemon start
```

Then relogin as your user to import `profile` variables and
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
daemon in `gentoo`:

```sh
emerge guix
# on systemd systems:
systemctl enable guix-daemon && systemctl start guix-daemon
# on openrc systems:
rc-update add guix-daemon && /etc/init.d/guix-daemon start
```

### First run

Upon first package installation `Guix` will create `~/.guix-profile` symlink to
`/var/guix/profiles/per-user/${USER}` (where `${USER}` is your user account
name in current shell).

In order to allow `Guix` to set all variables correctly execute those commands:

```sh
export GUIX_PROFILE="${HOME}/.guix-profile"
export GUIX_LOCPATH="${GUIX_PROFILE}/lib/locale"
source "${GUIX_PROFILE}/etc/profile"
```

The best way is to add the commands to your `${SHELL}` profile file:
`~/.profile` / `~/.bash_profile` / `~/.zprofile` or equivalent.

To install a `GNU hello` package to test out Guix execute:

```sh
guix package -i hello
```

If you plan to use `guix pull` (and you probably are) you'll need to add
it's `PATH` to your shell as well by following `guix pull`'s
[suggestion](https://guix.gnu.org/manual/en/html_node/Invoking-guix-pull.html):

```sh
export PATH="$HOME/.config/guix/current/bin:$PATH"
export INFOPATH="$HOME/.config/guix/current/share/info:$INFOPATH"
```

Next steps to try `guix` in action:

- <http://trofi.github.io/posts/197-guix-on-gentoo-howto.html>
- <https://guix.gnu.org/manual/>

# Known problems and workarounds

Ideally the above setup should Just Work. In practice sometimes bugs
happen outside `nix` or `guix` environments. When they come up and
are not yet fixed upstream we will list them here with possible
workarounds.

## Environment variables breaking emerge

### The symptom

```
/usr/sbin/gtk-encode-symbolic-svg: symbol lookup error: /guix/...-glibc-2.33/lib/libpthread.so.0:
  undefined symbol: __libc_pthread_init, version GLIBC_PRIVATE
```

This usually means your current environment contains unhandled
variables. You can look at `env` output to find which ones mention
`/nix/*` or `/gnu/*` store paths. Those are primary suspects.

Known problematic variables:

- none so far

Past examples:

- debugging poisoning by [GDK_PIXBUF_MODULE_FILE (fixed)](https://github.com/trofi/nix-guix-gentoo/issues/25)

### The workaround

Once you figured out what variable causes problems you can add it to the
list of `ENV_UNSET` variables in `/etc/portage/make.conf`. For example
if it was a `FOO_VARIABLE`:

```
# /etc/portage/make.conf
#  can be removed once fix lands in ::gentoo:
#     https://bugs.gentoo.org/...
ENV_UNSET="${ENV_UNSET} FOO_VARIABLE"
```

### Longer term fix

Longer term those variables should be reported in `::gentoo`. See
`Past examples` below for possible reports and fixes.

Pending fixes:

- none so far.

Past examples:

- [GDK_PIXBUF_MODULE_FILE](https://bugs.gentoo.org/887253)

### Detailed description

Some `nixpkgs` and `guix` packages set various environment variables to
redirect library loading from a default location to version-specific
directory. Usually it is done via scripts wrapping binaries. For example
`firefox` is a shell script that sets `LD_LIBRARY_PATH`, `XDG_DATA_DIRS`,
`GIO_EXTRA_MODULES`, `PATH` and then calls `.firefox-wrapped` `ELF`
executable.

Wrappers like that are usually contained to the wrapped program and
don't normally cause problems to other packages. Unless such packages
are able to spawn shells on their own. For example `konsole` exports
`QT_PLUGIN_PATH` in it's wrapper. Another typical example is `PATH`
variable.

The problem is not specific to `nixpkgs` or `guix`. Those are just most
extensive environment variable users with many parallel incompatible
environments available.

Normally `emerge` filters out problematic user variables by using
profiles' defaults specified in `ENV_UNSET` in `::gentoo` repository.
For example it's current value is:

```
gentoo $ git grep ENV_UNSET | tr ' ' $'\n'

profiles/base/make.defaults:ENV_UNSET="DBUS_SESSION_BUS_ADDRESS
DISPLAY
CARGO_HOME
GDK_PIXBUF_MODULE_FILE
XAUTHORITY
XDG_CACHE_HOME
XDG_CONFIG_HOME
XDG_DATA_HOME
XDG_STATE_HOME
XDG_RUNTIME_DIR
PERL_MM_OPT
PERL5LIB
PERL5OPT
PERL_MB_OPT
PERL_CORE
PERLPREFIX
GOBIN
GOPATH"
```

Some (many!) variables are not yet filtered by it. They are either
handled by `portage` explicitly (like `PATH` variables) or not handled
at all.

# Why use this overlay? Why not use official installation instructions?

That's a great question!

Here are installation instructions for:

- `nix`
  * [one liner](https://nixos.org/download.html)
  * [step by step](https://nixos.org/manual/nix/stable/installation/multi-user.html)
- `guix`
  * [one liner and step by step](https://guix.gnu.org/manual/en/html_node/Binary-Installation.html)

Why not just run those?

The aspirational goal of this overlay is to make both `nix` and `guix`
closer to typical packages one normally installs with `emerge`:
installation, upgrade and uninstall should not require extra actions or
special cleanups.

I'll list of some individual aspects below with their pros and cons to
give the reader to decide on their own:

## Install, Upgrade and Uninstall

Ebuild pros:

- install, upgrade and uninstall are done just like any other package
  via `emerge` (and via service registration). No need to update
  `nix-daemon` via `nix` package mechanism. Daemon just works.
- no need to manage separate `root`-based `nix` package just to update
  `nix-daemon`. Managing user's configurations is enough.
- rollbacks are done by emerging previous package version
- the binaries are built from source package using user's `USE`,
  `CFLAGS` and libraries. That makes `nix` and `guix` more adaptable to
  the environments where official binaries don't work as is.
- needed users and groups are installed and uninstalled along with the
  package. Adding extra groups to builders (like `kvm`) can be done via
  `make.conf` overrides with all power of `man acct-user.eclass`.
- the `nix` and `guix` binaries are installed to their usual `/usr`
  locations (`nixpkgs` packages still use `nix` as expected).
- all created files and directories are tracked by package manager,
  allow for natural cleanup on uninstall (apart from `/nix/`).
- ebuild does a bit of environment validation to make sure host kernel
  supports enough features to run nix build containers.

Ebuild cons:

- ebuild retraces the steps of the official install script: it very
  occasionally gets them wrong (usually on major updates). That might
  cause overlay-specific bugs.
- the binaries are built from source package using user's `USE`,
  `CFLAGS` and libraries (same as cons): feature set (and bug set) might
  be different from official upstream binary.
- by default `nix-daemon` version is defined by the ebuild, not by the
  package version installed via `nix`. It should not be an issue, but
  it's a deviation from typical setup.
