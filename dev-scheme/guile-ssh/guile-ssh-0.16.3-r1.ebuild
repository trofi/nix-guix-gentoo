# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::nix-guix note: we fork dev-scheme/guile-ssh to drop
# problematic patch that fixes(?) build on musl and breaks
# built on glibc+clang:
#   https://bugs.gentoo.org/903689
# I don't think that patch is correct.
#
# While at it re-enabled all tests. They seem to work as is.

EAPI=8

inherit autotools

DESCRIPTION="Library providing access to the SSH protocol for GNU Guile"
HOMEPAGE="https://memory-heap.org/~avp/projects/guile-ssh/
	https://github.com/artyom-poptsov/guile-ssh/"
SRC_URI="https://github.com/artyom-poptsov/${PN}/archive/v${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="strip"

RDEPEND="
	>=dev-scheme/guile-2.0.0:=
	net-libs/libssh:0=[server,sftp]
"
DEPEND="${RDEPEND}"

DOCS=( AUTHORS ChangeLog NEWS README THANKS TODO )

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_PREBUILT='*[.]go'

src_prepare() {
	default

	# http://debbugs.gnu.org/cgi/bugreport.cgi?bug=38112
	find "${S}" -name "*.scm" -exec touch {} + || die

	# the release lacks configure
	eautoreconf
}

src_install() {
	default

	find "${ED}" -name "*.la" -delete || die
}
