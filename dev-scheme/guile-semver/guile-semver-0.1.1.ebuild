# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 2-2 3-0 )

inherit autotools guile

DESCRIPTION="Guile library that handles Semantic Versions and NPM-style ranges."
HOMEPAGE="https://ngyro.com/software/guile-semver.html"

SRC_URI="https://files.ngyro.com/guile-semver/guile-semver-${PV}.tar.gz"
KEYWORDS="~amd64 ~x86"

LICENSE="LGPL-3+"
SLOT="0"
REQUIRED_USE="${GUILE_REQUIRED_USE}"

RDEPEND="
	${GUILE_DEPS}
"
DEPEND="
	${RDEPEND}
"

src_prepare() {
	guile_src_prepare
}

#src_test() {
#	guile_foreach_impl emake VERBOSE="1" check
#}
