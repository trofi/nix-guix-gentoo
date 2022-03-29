# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::nix-guix note: we fork app-text/lowdown::gentoo version:
# has a hard time providing working library:
# - https://bugs.gentoo.org/811111
# - https://bugs.gentoo.org/832590
# - https://bugs.gentoo.org/832797
# and is still broken in app-text/lowdown-0.11.1-r1 (missing liblowdown.so)
#
# To peacefully coexist with app-text/lowdown we install everything into a prefix.

EAPI=8

inherit toolchain-funcs

MY_PV="VERSION_${PV//./_}"
DESCRIPTION="Markdown translator producing HTML5, roff documents in the ms and man formats"
HOMEPAGE="https://kristaps.bsd.lv/lowdown/"
SRC_URI="https://github.com/kristapsdz/lowdown/archive/refs/tags/${MY_PV}.tar.gz -> lowdown-${PV}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	app-crypt/libmd:=
	virtual/libcrypt:=
"
RDEPEND="${DEPEND}"

S="${WORKDIR}/lowdown-${MY_PV}"

src_configure() {
	CC="$(tc-getCC)" \
		./configure \
			PREFIX=${EPREFIX}/usr/$(get_libdir)/lowdown-nix \
			|| die "./configure failed"
}

src_install() {
	default
	# install static libraries for sys-apps/nix
	emake DESTDIR="${D}" install_static
}
