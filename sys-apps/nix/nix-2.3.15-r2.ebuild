# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic linux-info readme.gentoo-r1 user

DESCRIPTION="A purely functional package manager"
HOMEPAGE="https://nixos.org/nix"

SRC_URI="http://nixos.org/releases/${PN}/${P}/${P}.tar.xz"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+etc-profile +gc doc s3 +sodium"

# sys-apps/busybox-nix-sandbox-shell is needed for sandbox mount of /bin/sh
RDEPEND="
	app-arch/brotli
	app-arch/bzip2
	app-arch/xz-utils
	sys-apps/busybox-nix-sandbox-shell
	dev-db/sqlite
	dev-libs/editline:0=
	>=dev-libs/boost-1.66:0=[context]
	net-misc/curl
	sys-libs/libseccomp
	sys-libs/zlib
	gc? ( dev-libs/boehm-gc[cxx] )
	doc? ( dev-libs/libxml2
		dev-libs/libxslt
		app-text/docbook-xsl-stylesheets
	)
	s3? ( dev-libs/aws-sdk-cpp[s3] )
	sodium? ( dev-libs/libsodium:0= )
	dev-libs/openssl:0=
"
DEPEND="${RDEPEND}
	>=sys-devel/bison-2.6
	>=sys-devel/flex-2.5.35
"

# https://github.com/trofi/nix-guix-gentoo/issues/8
# Account for missing upstream m4 files from tarball:
# dev-util/pkgconfig: m4/pkg.m4
# sys-devel/autoconf-archive: m4/ax_boost_base.m4, m4/ax_require_defined.m4
DEPEND+="
	sys-devel/autoconf-archive
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-2.3-libpaths.patch
	"${FILESDIR}"/${PN}-2.3-bootstrap.patch
	"${FILESDIR}"/${PN}-2.3-gc-crash.patch
	"${FILESDIR}"/${PN}-2.3.15-aws-sdk.patch
)

DISABLE_AUTOFORMATTING=yes
DOC_CONTENTS=" Quick start user guide on Gentoo:

[as root] enable nix-daemon service:
	[systemd] # systemctl enable nix-daemon && systemctl start nix-daemon
	[openrc]  # rc-update add nix-daemon && /etc/init.d/nix-daemon start
[as a user] relogin to get environment and profile update
[as a user] fetch nixpkgs update:
	\$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	\$ nix-channel --update
[as a user] install nix packages:
	\$ nix-env -i mc
[as a user] configure environment:
	Somewhere in .bash_profile you might want to set
	LOCALE_ARCHIVE=\$HOME/.nix-profile/lib/locale/locale-archive
	but please read https://github.com/NixOS/nixpkgs/issues/21820

Next steps:
	nix package manager user manual: http://nixos.org/nix/manual/
"

pkg_pretend() {
	# USER_NS is used to run builders in a default setting in linux:
	#     https://nixos.wiki/wiki/Nix#Sandboxing
	local CONFIG_CHECK="~USER_NS"
	check_extra_config
}

pkg_setup() {
	enewgroup nixbld
	for i in {1..10}; do
		# we list 'nixbld' twice to
		# both assign a primary group for user
		# and add a user to /etc/group
		enewuser nixbld${i} -1 -1 /var/empty nixbld,nixbld
	done
}

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	# Disable automagic depend:
	# - don't enable implicitly: bug #670256
	# - don't disable implicitly: https://github.com/trofi/nix-guix-gentoo/issues/12
	export ac_cv_header_aws_s3_S3Client_h=$(usex s3)

	econf \
		--localstatedir="${EPREFIX}"/nix/var \
		$(use_enable gc) \
		--with-sandbox-shell="${EPREFIX}"/usr/bin/busybox-nix-sandbox-shell
}

src_compile() {
	emake V=1
}

src_install() {
	# TODO: emacs highlighter
	default

	readme.gentoo_create_doc

	# TODO: will need a tweak for prefix

	# Follow the steps of 'scripts/install-multi-user.sh:create_directories()'
	local dir dirs=(
		/nix
		/nix/var
		/nix/var/log
		/nix/var/log/nix
		/nix/var/log/nix/drvs
		/nix/var/nix{,/db,/gcroots,/profiles,/temproots,/userpool}
		/nix/var/nix/{gcroots,profiles}/per-user
	)
	for dir in "${dirs[@]}"; do
		keepdir "${dir}"
		fperms 0755 "${dir}"
	done

	keepdir             /nix/store
	fowners root:nixbld /nix/store
	fperms 1775         /nix/store

	newinitd "${FILESDIR}"/nix-daemon.initd nix-daemon

	if ! use etc-profile; then
		rm "${ED}"/etc/profile.d/nix.sh || die
		rm "${ED}"/etc/profile.d/nix-daemon.sh || die
	fi
}

pkg_postinst() {
	if ! use etc-profile; then
		ewarn "${EROOT}/etc/profile.d/nix.sh was removed (due to USE=-etc-profile)."
	fi

	readme.gentoo_print_elog
}
