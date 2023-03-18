# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="zstd module for Guile"
HOMEPAGE="https://notabug.org/guile-zstd/guile-zstd"
SRC_URI="https://notabug.org/guile-zstd/guile-zstd/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# In zstd-1.5.2-r2 library was moved from /usr/lib to /lib
RDEPEND="
	>=dev-scheme/guile-2.0.0:=
	>=app-arch/zstd-1.5.2-r2:0=
"
DEPEND="${RDEPEND}"

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_PREBUILT='*[.]go'

S=${WORKDIR}/guile-zstd

src_prepare() {
	default

	# Workaround gentoo-specific deviation where
	# /usr/lib64/libzstd.so is a linker script that points to:
	#   GROUP ( /lib64/libzstd.so.1 )
	# This confuses guile-zstd and fails to open the library:
	#   substitute: ice-9/boot-9.scm:1685:16: In procedure raise-exception:
	#   substitute: In procedure load-foreign-library: file: "/usr/lib64/libzstd.so.1",
	#     message: "file not found"
	#   guix environment: error: `/usr/bin/guix substitute' died unexpectedly
	sed -i -e "s,@ZSTD_LIBDIR@/libzstd.so.1,${EPREFIX}/$(get_libdir)/libzstd.so.1," \
		zstd/config.scm.in || die

	eautoreconf
}
