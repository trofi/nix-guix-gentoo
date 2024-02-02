# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake vcs-snapshot

DESCRIPTION="Property based testing framework inspired by QuickCheck"
HOMEPAGE="https://github.com/emil-e/rapidcheck"

COMMIT_ID=ff6af6fc683159deb51c543b065eba14dfcf329b
SRC_URI="https://github.com/emil-e/rapidcheck/archive/${COMMIT_ID}.tar.gz -> ${P}.tar.gz"
LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-build/cmake
"

src_configure() {
	local mycmakeargs+=(
		-DRC_INSTALL_ALL_EXTRAS=YES
	)
	cmake_src_configure
}
