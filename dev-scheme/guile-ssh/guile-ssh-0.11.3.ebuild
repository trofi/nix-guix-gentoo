# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="SSH module for Guile"
HOMEPAGE="https://github.com/artyom-poptsov"
SRC_URI="https://github.com/artyom-poptsov/guile-ssh/archive/v${PV}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RESTRICT=test # needs interactive input

RDEPEND="
	>=dev-scheme/guile-2.0.0
	net-libs/libssh:0=[server]
"
DEPEND="${RDEPEND}"

src_prepare() {
	default

	eautoreconf
}
