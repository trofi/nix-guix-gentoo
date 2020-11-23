# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="zilb module for Guile"
HOMEPAGE="https://notabug.org/guile-zlib/guile-zlib"
SRC_URI="https://notabug.org/guile-zlib/guile-zlib/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RESTRICT=test # testsuite has type errors

RDEPEND="
	>=dev-scheme/guile-2.0.0:=
	sys-libs/zlib:0=
"
DEPEND="${RDEPEND}"

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_FLAGS_IGNORED='.*[.]go'

S=${WORKDIR}/guile-zlib

src_prepare() {
	default

	eautoreconf
}
