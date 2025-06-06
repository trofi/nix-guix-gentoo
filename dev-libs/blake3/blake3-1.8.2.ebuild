# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# ::nix-guix note: we update the package as ::Gentoo one is a bit
# outdated. Update it enough to satisfy sys-apps/nix-2.29.0 dependency.

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
inherit cmake python-any-r1

DESCRIPTION="a fast cryptographic hash function"
HOMEPAGE="https://github.com/BLAKE3-team/BLAKE3"
SRC_URI="https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/BLAKE3-${PV}/c"

LICENSE="|| ( CC0-1.0 Apache-2.0 )"
SLOT="0/0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~arm64-macos ~x64-macos"
IUSE="test"
RESTRICT="!test? ( test )"
BDEPEND="test? ( ${PYTHON_DEPS} )"

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DBLAKE3_BUILD_TESTING="$(usex test)"
	)
	cmake_src_configure
}
