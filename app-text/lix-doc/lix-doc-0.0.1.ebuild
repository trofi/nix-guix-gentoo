# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Autogenerated by pycargoebuild 0.13.4

EAPI=8

CRATES="
	autocfg@1.1.0
	countme@3.0.1
	dissimilar@1.0.7
	expect-test@1.4.1
	hashbrown@0.14.5
	memoffset@0.9.1
	once_cell@1.19.0
	rnix@0.11.0
	rowan@0.15.15
	rustc-hash@1.1.0
	text-size@1.1.1
"

inherit cargo

DESCRIPTION="Nix function documentation tool, stripped down into a library"
HOMEPAGE="https://github.com/lf-/nix-doc"
SRC_URI="
	${CARGO_CRATE_URIS}
"

LICENSE="|| ( BSD-2 MIT )"
# Dependent crate licenses
LICENSE+=" Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64"

# Added manually after pycargoebuild run:
#
LIX_PV=2.91.1
LIX_P=lix-${LIX_PV}
SRC_URI+="
	https://git.lix.systems/lix-project/lix/archive/${LIX_PV}.tar.gz -> ${LIX_P}.tar.gz
"
S=$WORKDIR/lix/lix-doc

cargo_src_install() {
	# clobber the default install as it fails to install the static library as:
	# $ cargo install --path . --root ${PWD}/__i__
	# error: no packages found with binaries or examples

	# Pick a file like 'target/x86_64-unknown-linux-gnu/release/liblix_doc.a'
	dolib.a target/*/*/liblix_doc.a
}