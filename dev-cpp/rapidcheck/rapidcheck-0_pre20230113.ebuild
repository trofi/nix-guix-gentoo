# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake vcs-snapshot

DESCRIPTION="Property based testing framework inspired by QuickCheck"
HOMEPAGE="https://github.com/emil-e/rapidcheck"

COMMIT_ID=1505cbbce733bde3b78042cf2e9309c0b7f227a2
SRC_URI="https://github.com/emil-e/rapidcheck/archive/${COMMIT_ID}.tar.gz -> ${P}.tar.gz"
LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	dev-util/cmake
"

src_install() {
	cmake_src_install

	# used by sys-apps/nix
	cp -rv "${S}"/extras ${ED}/usr/include/rapidcheck || die
}
