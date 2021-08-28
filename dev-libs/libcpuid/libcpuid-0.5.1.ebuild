# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="CPU identification library for the x86"
HOMEPAGE="https://github.com/anrieff/libcpuid"
SRC_URI="https://github.com/anrieff/libcpuid/releases/download/v${PV}/${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0/15" # libcpuid.so.15

KEYWORDS="~amd64 ~x86"
