# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools linux-info readme.gentoo-r1 tmpfiles toolchain-funcs

DESCRIPTION="A purely functional package manager"
HOMEPAGE="https://nixos.org/nix"

SRC_URI="https://github.com/NixOS/nix/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+etc-profile +gc doc +sodium"

# sys-apps/busybox-nix-sandbox-shell is needed for sandbox mount of /bin/sh
RDEPEND="
	app-arch/brotli
	app-arch/bzip2
	app-arch/xz-utils
	app-misc/jq
	app-text/lowdown-nix
	dev-cpp/gtest
	dev-db/sqlite
	dev-libs/editline:0=
	dev-libs/libcpuid:0=
	dev-libs/openssl:0=
	>=dev-libs/boost-1.66:0=[context]
	net-misc/curl
	sys-apps/busybox-nix-sandbox-shell
	sys-libs/libseccomp
	sys-libs/zlib
	gc? ( dev-libs/boehm-gc[cxx] )
	doc? ( dev-libs/libxml2
		dev-libs/libxslt
		app-text/docbook-xsl-stylesheets
	)
	sodium? ( dev-libs/libsodium:0= )
"
# add users and groups
RDEPEND+="
	acct-group/nixbld
"
for i in {1..64}; do
	RDEPEND+="
		>=acct-user/nixbld${i}-1
	"
done
DEPEND="${RDEPEND}
	app-text/mdbook
        app-text/mdbook-linkcheck
	dev-cpp/nlohmann_json
	>=sys-devel/bison-2.6
	>=sys-devel/flex-2.5.35
"

# Upstream does not bundle .m4 files, extract from upstreams:
# dev-util/pkgconfig: m4/pkg.m4
# sys-devel/autoconf-archive: m4/ax_boost_base.m4, m4/ax_require_defined.m4
DEPEND+="
	sys-devel/autoconf-archive
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-2.10-libpaths.patch
	"${FILESDIR}"/${PN}-2.13-DESTDIR.patch
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

	eautoreconf

	# rely on users settings
	sed 's/GLOBAL_CXXFLAGS += -O3/GLOBAL_CXXFLAGS += /' -i Makefile || die
	sed 's/GLOBAL_CXXFLAGS += -O3/GLOBAL_CXXFLAGS += /' -i perl/Makefile || die

	# inject our copy of lowdown-nix
	export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}${PKG_CONFIG_PATH:+:}${EPREFIX}/usr/$(get_libdir)/lowdown-nix/lib/pkgconfig"
	export PATH="$PATH:${EPREFIX}/usr/$(get_libdir)/lowdown-nix/bin"
}

src_configure() {
	CONFIG_SHELL="${BROOT}/bin/bash" econf \
		--localstatedir="${EPREFIX}"/nix/var \
		$(use_enable gc) \
		--with-sandbox-shell="${EPREFIX}"/usr/bin/busybox-nix-sandbox-shell

	emake Makefile.config # gets generated late
	cat >> Makefile.config <<-EOF
	V = 1
	CC = $(tc-getCC)
	CXX = $(tc-getCXX)
	EOF
}

src_compile() {
	# Upstream does not support building without installation.
	# Rely on src_install's DESTDIR=.
	:
}

src_install() {
	# TODO: emacs highlighter
	default

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
