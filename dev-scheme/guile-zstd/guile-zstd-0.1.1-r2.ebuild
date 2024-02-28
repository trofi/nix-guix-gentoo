# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::nix-guix note: fix `zstd` path detection to fix library dynamic
# loading: https://github.com/trofi/nix-guix-gentoo/issues/23#issuecomment-1968549670

EAPI=8

inherit autotools

DESCRIPTION="GNU Guile bindings to the zstd compression library"
HOMEPAGE="https://notabug.org/guile-zstd/guile-zstd/"
SRC_URI="https://notabug.org/${PN}/${PN}/archive/v${PV}.tar.gz
	-> ${P}.tar.gz"
S="${WORKDIR}"/${PN}

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# In zstd-1.5.5-r1 library was moved from /lib to /usr/lib
RDEPEND="
	>=dev-scheme/guile-2.0.0:=
	>=app-arch/zstd-1.5.5-r1
"
DEPEND="${RDEPEND}"

DOCS=( AUTHORS ChangeLog NEWS README )

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_PREBUILT='*[.]go'

src_prepare() {
	default

	# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=38112
	find "${S}" -name "*.scm" -exec touch {} + || die

	eautoreconf
}

src_install() {
	default

	# Workaround llvm-strip problem of mangling guile ELF debug
	# sections: https://bugs.gentoo.org/905898
	dostrip -x "/usr/$(get_libdir)/guile"
}
