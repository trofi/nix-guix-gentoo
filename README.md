# Nix and Guix for Gentoo

Gentoo overlay for [Nix](https://nixos.org/) and
[GNU Guix](https://guix.gnu.org/) functional package managers.

# Enabling the overlay

Use standard [repos.conf](https://wiki.gentoo.org/wiki//etc/portage/repos.conf)
configuration for the overlay:

```bash
# make sure 'repos.conf' is present:
mkdir -p /etc/portage/repos.conf

# Add an entry
cat > /etc/portage/repos.conf/nix-guix.conf <<EOF
[nix-guix]
location = /var/db/repos/nix-guix
sync-type = git
sync-uri = https://github.com/trofi/nix-guix-gentoo.git
EOF

# Sync the overlay
emerge --sync
```

Finally, we need to unmask the overlay (this does not apply if your system
is already running ~arch):

```sh
# create keywords directory:
mkdir -p /etc/portage/package.accept_keywords

# Unmask ~testing versions for your arch:
echo "*/*::nix-guix" >> /etc/portage/package.accept_keywords/nix-guix

# (guix only) Unmask hard-masked guile and guix:
mkdir -p /etc/portage/package.unmask
echo "sys-apps/guix::nix-guix" >> /etc/portage/package.unmask/nix-guix
echo "dev-scheme/guile"        >> /etc/portage/package.unmask/nix-guix
echo "dev-scheme/guile"        >> /etc/portage/package.accept_keywords/nix-guix
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

You are done! Except you have no packages.

Now it's a good idea to check basic functionality:

```
# run a program without installation:
nix-shell -p re2c --run "re2c --version"
> re2c 3.0

# install and run a program with nix-env (impure):
nix-env -iA nixpkgs.re2c
> installing 're2c-3.0'

re2c --version
> re2c 3.0
```

Install some packages declaratively: 

Next steps to try `nix` in action:

- <https://trofi.github.io/posts/196-nix-on-gentoo-howto.html>
- <https://nixos.org/manual/nixpkgs/stable/>
- use a profile/flake <https://github.com/equwal/nixtoo-genux/tree/master>

## Guix

### Installation

The installation follows typical process of installing a daemon in
`gentoo`:

```sh
emerge guix
# on systemd systems:
systemctl enable guix-daemon && systemctl start guix-daemon
# on openrc systems:
rc-update add guix-daemon && /etc/init.d/guix-daemon start
```

You will likely want to enable binary cache:

```sh
guix archive --authorize < /usr/share/guix/ci.guix.gnu.org.pub
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

## Missing sandbox support

The typical symptom is a failure to set the sandbox up when the build is
required. Example test at rebuilding the package:

```
# fetching from cache:
$ nix-build --no-link '<nixpkgs>' -A hello
...
/nix/store/s66mzxpvicwk07gjbjfw9izjfa797vsw-hello-2.12.1

$ nix-build --check --no-link '<nixpkgs>' -A hello
error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
```

Here `error: this system does not support the kernel namespaces that are
required for sandboxing` is a symptom that your system fails to enable
`chroot` sandbox that relies on kernel's `PID` and `USER` (mount)
namespaces.

There are a few possible reasons for it:

1. Missing namespace support in the kernel

   Make sure you have those enabled:

   ```
   # zcat /proc/config.gz | grep -P 'CONFIG_USER_NS|PID_NS'
   CONFIG_USER_NS=y
   CONFIG_PID_NS=y
   ```

   Fix: build kernel with `USER_NS` and `PID_NS` support.

2. Already present read-only mounts within `/proc`

   These read-only entries are usually placed by by container managers
   like `docker` and `systemd-nspawn`. Example entries:

   ```
   # mount | grep proc
   proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
   proc on /proc/sys type proc (ro,nosuid,nodev,noexec,relatime)
   proc on /proc/acpi type proc (ro,nosuid,nodev,noexec,relatime)
   proc on /proc/asound type proc (ro,nosuid,nodev,noexec,relatime)
   proc on /proc/bus type proc (ro,nosuid,nodev,noexec,relatime)
   proc on /proc/fs type proc (ro,nosuid,nodev,noexec,relatime)
   proc on /proc/irq type proc (ro,nosuid,nodev,noexec,relatime)
   proc on /proc/scsi type proc (ro,nosuid,nodev,noexec,relatime)
   tmpfs on /proc/sys/kernel/random/boot_id type tmpfs (ro,nosuid,nodev,noexec,size=26371500k,nr_inodes=819200,mode=755)
   tmpfs on /proc/sys/kernel/random/boot_id type tmpfs (rw,nosuid,nodev,size=26371500k,nr_inodes=819200,mode=755)
   tmpfs on /proc/kmsg type tmpfs (rw,nosuid,nodev,size=26371500k,nr_inodes=819200,mode=755)
   ```

   Multiple `ro` mounts under `/proc` are a problem here. You need to
   find which mounts are causing the problem here. Some of them are safe
   and some are interfering with `nix-daemon`'s `/proc` remount:

   See [this post](https://lore.kernel.org/lkml/87tvsrjai0.fsf@xmission.com/T/)
   for more details on why it fails.

   Fix: TODO. Not sure what the correct fix here is yet. As a workaround
   to make sure it's the `/proc` masking issue you can unmount all of
   the `/proc` sub-mounts in the container:
   ```
   # umount /proc/kmsg /proc/scsi /proc/irq ...
   ```
   and restart `nix-daemon`.

   Maybe `systemd`'s `ProtectKernelTunables=no` could help as a
   workaround?

   Healthy state should look like this:
   ```
   # mount | fgrep proc
   proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)

   $ nix-build --check --no-link '<nixpkgs>' -A hello
   ...
   checking outputs of '/nix/store/ib3sh3pcz10wsmavxvkdbayhqivbghlq-hello-2.12.1.drv'...
   unpacking sources
   ...
   stripping (with command strip and flags -S -p) in  /nix/store/...-hello-2.12.1/bin
   /nix/store/...-hello-2.12.1
   ```

If you absolutely must disable sandbox then you can set
`sandbox-fallback = false` in `/etc/nix/nix.conf` and restart
`nix-daemon`. But things will leak out and break. You have been warned.

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
gentoo.git $ git grep ENV_UNSET | tr ' ' $'\n'

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
