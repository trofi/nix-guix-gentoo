# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
EAPI=8

inherit cmake

DESCRIPTION="TOML for Modern C++"
HOMEPAGE="https://github.com/ToruNiina/toml11"
SRC_URI="https://github.com/ToruNiina/toml11/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

src_configure() {
	local mycmakeargs=(
		# Build system insists on some option. Does not matter
		# in practice as we don't install anything outside
		# headers.
		-DCMAKE_CXX_STANDARD=11
	)
	cmake_src_configure
}

