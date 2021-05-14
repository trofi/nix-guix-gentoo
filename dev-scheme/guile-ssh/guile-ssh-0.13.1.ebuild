# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="SSH module for Guile"
HOMEPAGE="https://github.com/artyom-poptsov/guile-ssh"
SRC_URI="https://github.com/artyom-poptsov/guile-ssh/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RESTRICT=test # needs interactive input

RDEPEND="
	>=dev-scheme/guile-2.0.0:=
	net-libs/libssh:0=[server]
"
DEPEND="${RDEPEND}"

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_FLAGS_IGNORED='.*[.]go'

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
