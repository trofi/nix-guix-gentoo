# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="zilb module for Guile"
HOMEPAGE="https://notabug.org/guile-zlib/guile-zlib"
SRC_URI="https://notabug.org/guile-zlib/guile-zlib/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	>=dev-scheme/guile-3:=
	sys-libs/zlib:0=
"
DEPEND="${RDEPEND}"

PATCHES=("${FILESDIR}"/${PN}-0.1.0-gentoo.patch)

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_FLAGS_IGNORED='.*[.]go'

S=${WORKDIR}/guile-zlib

src_prepare() {
	default

	eautoreconf

	# guile is trying to avoid recompilation by checking if file
	#     /usr/lib64/guile/2.2/site-ccache/<foo>
	# is newer than
	#     <foo>
	# In case it is instead of using <foo> guile
	# loads system one (from potentially older version of package).
	# To work it around we bump last modification timestamp of
	# '*.scm' files.
	# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=38112
	find "${S}" -name "*.scm" -exec touch {} + || die
}

src_configure() {
	# Gentoo installs zlib to /${libdir} and to /usr/${libdir}.
	# We need /${libdir} with shared library here.
	econf LIBZ_LIBDIR="${EPREFIX}/$(get_libdir)"
}
