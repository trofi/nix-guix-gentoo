# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# NOTE: sys-apps/lix is heavily derived from sys-apps/nix. Chances are
# that changes related to on-disk layout should be applied to both.

EAPI=8

inherit linux-info meson readme.gentoo-r1 tmpfiles

DESCRIPTION="A purely functional package manager (nix fork)"
HOMEPAGE="https://lix.systems/"

SRC_URI="https://git.lix.systems/lix-project/lix/archive/${PV}.tar.gz -> ${P}.tar.gz"
S=${WORKDIR}/lix
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+allocate-build-users +etc-profile +gc doc"

BDEPEND="
	doc? ( app-text/mdbook
		app-text/mdbook-linkcheck
	)
"
# sys-apps/busybox-nix-sandbox-shell is needed for sandbox mount of /bin/sh
# sys-kernel/linux-headers is needed to have newer syscal numbers for seccomp:
#   https://github.com/trofi/nix-guix-gentoo/issues/52#issuecomment-2461969243
RDEPEND="
	app-arch/brotli
	app-arch/bzip2
	app-arch/xz-utils
	app-misc/jq
	app-text/lowdown-nix
	dev-cpp/gtest
	dev-db/sqlite
	dev-libs/editline:0=
	dev-libs/libgit2:0=
	amd64? ( dev-libs/libcpuid:0= )
	app-arch/libarchive:0=
	dev-libs/openssl:0=
	dev-libs/pegtl:0=
	dev-libs/libsodium:0=
	>=dev-libs/boost-1.66:0=[context]
	net-misc/curl
	sys-apps/busybox-nix-sandbox-shell
	>=sys-kernel/linux-headers-6.7
	sys-libs/libseccomp
	sys-libs/zlib
	gc? ( >=dev-libs/boehm-gc-8.2.6[cxx] )
	doc? ( dev-libs/libxml2
		dev-libs/libxslt
		app-text/docbook-xsl-stylesheets
	)
"
# add users and groups
RDEPEND+="
	acct-group/nixbld
	allocate-build-users? (
"
for i in {1..64}; do
	RDEPEND+="
		>=acct-user/nixbld${i}-1
	"
done
RDEPEND+="
	)
"
DEPEND="${RDEPEND}
	app-text/lix-doc
	dev-cpp/nlohmann_json
	dev-cpp/toml11
	>=dev-cpp/rapidcheck-0_pre20231214
	>=sys-devel/bison-2.6
	>=sys-devel/flex-2.5.35
"

# lix is a drop-in replacement of sys-apps/nix: it installs the same
# binary file names.
RDEPEND+="
	!!sys-apps/nix
"

PATCHES=(
	# local patch
	"${FILESDIR}"/lix-2.91.1-no-sandbox-fallback.patch
	"${FILESDIR}"/lix-2.91.1-no-sandbox-fallback-README.patch
	# backports
	"${FILESDIR}"/lix-2.91.1-no-coreutils.patch
)

DISABLE_AUTOFORMATTING=yes
DOC_CONTENTS=" Quick start user guide on Gentoo:

[as root] enable nix-daemon service:
	[systemd] # systemctl enable nix-daemon && systemctl start nix-daemon
	[openrc]  # rc-update add nix-daemon && /etc/init.d/nix-daemon start
[as a user] relogin to get environment and profile update
[as a user] fetch nixpkgs update:
	\$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	\$ nix-channel --update
[as a user] install nix packages:
	\$ nix-env -i mc
[as a user] configure environment:
	Somewhere in .bash_profile you might want to set
	LOCALE_ARCHIVE=\$HOME/.nix-profile/lib/locale/locale-archive
	but please read https://github.com/NixOS/nixpkgs/issues/21820

Next steps:
	nix package manager user manual: http://nixos.org/nix/manual/
"

pkg_pretend() {
	# USER_NS is used to run builders in a default setting in linux:
	#     https://nixos.wiki/wiki/Nix#Sandboxing
	local CONFIG_CHECK="~USER_NS"
	check_extra_config
}

src_prepare() {
	default

	# inject our copy of lowdown-nix
	export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}${PKG_CONFIG_PATH:+:}${EPREFIX}/usr/$(get_libdir)/lowdown-nix/lib/pkgconfig"
	export PATH="$PATH:${EPREFIX}/usr/$(get_libdir)/lowdown-nix/bin"

	# inject rapidcheck extra includes
	export CXXFLAGS="${CXXFLAGS} -I${EPREFIX}/usr/include/rapidcheck/extras/gtest/include"

	# Avoid sandbox failures accessing /var/lib/portage/home/.local
	sed -e "s@'/dummy@'${T}/dummy@g" -i doc/manual/meson.build || die
}

src_configure() {
	local emesonargs=(
		$(meson_feature gc)
		$(meson_use doc enable-docs)
		-Dprofile-dir="${EPREFIX}"/etc/profile.d
		-Dstate-dir="${EPREFIX}"/nix/var
		-Dsandbox-shell="${EPREFIX}"/usr/bin/busybox-nix-sandbox-shell
	)
	meson_src_configure
}

src_install() {
	# TODO: emacs highlighter
	meson_src_install

	readme.gentoo_create_doc

	# TODO: will need a tweak for prefix

	# Follow the steps of 'scripts/install-multi-user.sh:create_directories()'
	local dir dirs=(
		/nix
		/nix/var
		/nix/var/log
		/nix/var/log/nix
		/nix/var/log/nix/drvs
		/nix/var/nix{,/db,/gcroots,/profiles,/temproots,/userpool,/daemon-socket}
		/nix/var/nix/{gcroots,profiles}/per-user
	)
	for dir in "${dirs[@]}"; do
		keepdir "${dir}"
		fperms 0755 "${dir}"
	done

	keepdir             /nix/store
	fowners root:nixbld /nix/store
	fperms 1775         /nix/store

	newinitd "${FILESDIR}"/nix-daemon.initd nix-daemon

	if ! use etc-profile; then
		rm "${ED}"/etc/profile.d/nix.sh || die
	fi
	# nix-daemon.sh should not be used for users' profile.
	# Only for daemon itself.
	rm "${ED}"/etc/profile.d/nix-daemon.sh || die
}

pkg_postinst() {
	if ! use etc-profile; then
		ewarn "${EROOT}/etc/profile.d/nix.sh was removed (due to USE=-etc-profile)."
	fi

	readme.gentoo_print_elog
	tmpfiles_process nix-daemon.conf
}