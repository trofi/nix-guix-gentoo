# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::nix-guix note: we build capnproto with -std=gnu++20 to expose
# coroutine API needed by sys-apps/lix package.

EAPI=8

inherit cmake flag-o-matic

DESCRIPTION="RPC/Serialization system with capabilities support"
HOMEPAGE="https://capnproto.org"
SRC_URI="https://github.com/sandstorm-io/capnproto/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}"/${P}/c++

LICENSE="MIT"
SLOT="0/${PV}"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc ~ppc64 ~riscv ~x86"
IUSE="+cxx20 +ssl test zlib"
RESTRICT="!test? ( test )"

RDEPEND="
	ssl? ( dev-libs/openssl:= )
	zlib? ( sys-libs/zlib:= )
"
DEPEND="
	${RDEPEND}
	test? ( dev-cpp/gtest )
"

src_configure() {
	use cxx20 && append-cxxflags -std=gnu++20

	append-atomic-flags
	if [[ ${LIBS} == *atomic* ]] ; then
		# append-libs won't work here, cmake doesn't respect it
		# ... and ldflags gets missed once
		append-flags -latomic
	fi

	local mycmakeargs=(
		-DBUILD_TESTING=$(usex test)
		-DWITH_OPENSSL=$(usex ssl)
		-DWITH_ZLIB=$(usex zlib)
	)

	cmake_src_configure
}

src_test() {
	cmake_build check
}
