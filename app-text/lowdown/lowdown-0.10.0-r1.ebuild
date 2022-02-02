# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::nix-guix note:
# - fix library installation (needed by nix): https://bugs.gentoo.org/832590

EAPI=8

inherit toolchain-funcs

MY_PV="VERSION_${PV//./_}"
DESCRIPTION="Markdown translator producing HTML5, roff documents in the ms and man formats"
HOMEPAGE="https://kristaps.bsd.lv/lowdown/"
SRC_URI="https://github.com/kristapsdz/lowdown/archive/refs/tags/${MY_PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_PV}"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	app-crypt/libmd
	virtual/libcrypt:=
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-0.8.4-shared.patch
)

src_configure() {
	CC="$(tc-getCC)" \
		./configure \
			PREFIX=${EPREFIX}/usr \
			MANDIR=${EPREFIX}/usr/share/man \
			LIBDIR=${EPREFIX}/usr/$(get_libdir) || die "./configure failed"
}

src_compile() {
	emake LDFLAGS="${LDFLAGS}" AR="$(tc-getAR)" $(usex elibc_musl UTF8_LOCALE=C.UTF-8 '')
}

src_test() {
	emake regress
}
