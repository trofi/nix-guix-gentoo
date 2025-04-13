# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GUILE_COMPAT=( 3-0 )
GUILE_REQ_USE="regex,networking,threads"
inherit autotools git-r3 guile-single linux-info readme.gentoo-r1 systemd

DESCRIPTION="GNU package manager (nix sibling)"
HOMEPAGE="https://www.gnu.org/software/guix/"

# taken from gnu/local.mk and gnu/packages/bootstrap.scm
BOOT_GUILE=(
	"aarch64-linux  20170217 guile-2.0.14.tar.xz"
	"armhf-linux    20150101 guile-2.0.11.tar.xz"
	"i686-linux     20131110 guile-2.0.9.tar.xz"
	"mips64el-linux 20131110 guile-2.0.9.tar.xz"
	"x86_64-linux   20131110 guile-2.0.9.tar.xz"
)

binary_src_uris() {
	local system_date_guilep uri
	for system_date_guilep in "${BOOT_GUILE[@]}"; do
		# $1              $2       $3
		# "armhf-linux    20150101 guile-2.0.11.tar.xz"
		set -- ${system_date_guilep}
		uri="https://alpha.gnu.org/gnu/${PN}/bootstrap/$1/$2/$3"
		# ${uri} -> guix-bootstrap-armhf-linux-20150101-guile-2.0.11.tar.xz.bootstrap
		echo "${uri} -> guix-bootstrap-$1-$2-$3.bootstrap"
	done
}

# copy bootstrap binaries from DISTDIR to ${S}
copy_boot_guile_binaries() {
	local system_date_guilep
	for system_date_guilep in "${BOOT_GUILE[@]}"; do
		# $1              $2       $3
		# "armhf-linux    20150101 guile-2.0.11.tar.xz"
		set -- ${system_date_guilep}
		mkdir -p gnu/packages/bootstrap/$1 || die
		cp "${DISTDIR}"/guix-bootstrap-$1-$2-$3.bootstrap gnu/packages/bootstrap/$1/$3 || die
	done
}

SRC_URI="$(binary_src_uris)"
EGIT_REPO_URI="https://git.savannah.gnu.org/git/guix.git"

LICENSE="GPL-3"
SLOT="0"
#KEYWORDS="~amd64 ~x86"

RESTRICT=test # complains about size of config.log and refuses to start tests

# guile-3.0.10 fails to expand some syntax maacros

RDEPEND="
	dev-libs/libgcrypt:0=
	${GUILE_DEPS}
	$(guile_gen_cond_dep '
		dev-scheme/bytestructures[${GUILE_MULTI_USEDEP}]
		dev-scheme/guile-gcrypt[${GUILE_MULTI_USEDEP}]
		>=dev-scheme/guile-git-0.2.0[${GUILE_MULTI_USEDEP}]
		>=dev-scheme/guile-json-4.3[${GUILE_MULTI_USEDEP}]
		dev-scheme/guile-lib[${GUILE_MULTI_USEDEP}]
		dev-scheme/guile-lzlib[${GUILE_MULTI_USEDEP}]
		dev-scheme/guile-sqlite3[${GUILE_MULTI_USEDEP}]
		dev-scheme/guile-ssh[${GUILE_MULTI_USEDEP}]
		>=dev-scheme/guile-zstd-0.1.1-r2[${GUILE_MULTI_USEDEP}]
		>=dev-scheme/guile-zlib-0.1.0-r2[${GUILE_MULTI_USEDEP}]
		dev-scheme/guile-gnutls[${GUILE_MULTI_USEDEP}]
	')
	sys-libs/zlib
	app-arch/bzip2
	dev-db/sqlite
"
# add users and groups
RDEPEND+="
	acct-group/guixbuild
"
for i in {1..64}; do
	RDEPEND+="
		>=acct-user/guixbuilder${i}-1
	"
done
# media-gfx/graphviz provides 'dot'. Not needed for
# release tarballs.
# >=app-text/po4a-0.69-r1 is needed to generate
# documentation. It needs to also include patch
# pending upstream inclusion:
#   https://github.com/mquinson/po4a/pull/437
DEPEND="${RDEPEND}
	media-gfx/graphviz
	>=app-text/po4a-0.69-r1
"

PATCHES=(
	"${FILESDIR}"/${PN}-9999-default-daemon.patch
	"${FILESDIR}"/${PN}-1.3.0-compression-error.patch
	"${FILESDIR}"/${PN}-9999-gcc-15.patch
	"${FILESDIR}"/${PN}-9999-gcc-15-p2.patch
)

QA_PREBUILT="usr/share/guile/site/*/gnu/packages/bootstrap/*"

# guile generates ELF files without use of C or machine code
# It's a portage's false positive. bug #677600
QA_PREBUILT+=' *[.]go'

DISABLE_AUTOFORMATTING=yes
DOC_CONTENTS="Quick start user guide on Gentoo:

[as root] allow binary substitution to be downloaded (optional)
	# guix archive --authorize < /usr/share/guix/ci.guix.gnu.org.pub
[as root] enable guix-daemon service:
	[systemd] # systemctl enable guix-daemon && systemctl start guix-daemon
	[openrc]  # rc-update add guix-daemon && /etc/init.d/guix-daemon start
[as a user] ln -sf /var/guix/profiles/per-user/\$USER/guix-profile \$HOME/.guix-profile
[as a user] install guix packages:
	\$ guix package -i hello
[as a user] configure environment:
	Somewhere in .bash_profile you might want to set
	export GUIX_LOCPATH=\$HOME/.guix-profile/lib/locale

Next steps:
	guix package manager user manual: https://www.gnu.org/software/guix/manual/guix.html
"

pkg_pretend() {
	# USER_NS is used to run builders in a default setting in linux
	# and for 'guix environment --container'.
	local CONFIG_CHECK="~USER_NS"
	check_extra_config
}

pkg_setup() {
	guile-single_pkg_setup
	linux-info_pkg_setup
}

src_prepare() {
	copy_boot_guile_binaries

	default

	./bootstrap || die

	# build system is very eager to run automake itself: bug #625166
	eautoreconf

	guile_bump_sources

	# Gentoo stores systemd unit files in lib, never in lib64: bug #689772
	sed -i nix/local.mk \
		-e 's|systemdservicedir = $(libdir)/systemd/system|systemdservicedir = '"$(systemd_get_systemunitdir)"'|' || die

	sed -i \
		build-aux/mdate-from-git.scm \
		build-aux/test-driver.scm \
		build-aux/xgettext.scm \
		gnu/packages/game-development.scm \
		-e "s|exec guile |exec ${GUILE} |g" || die
}

src_configure() {
	# to be compatible with guix from /gnu/store
	econf \
		--localstatedir="${EPREFIX}"/var
}

src_install() {
	# TODO: emacs highlighter
	default

	readme.gentoo_create_doc

	keepdir                /etc/guix
	# TODO: will need a tweak for prefix
	keepdir                /gnu/store
	fowners root:guixbuild /gnu/store
	fperms 1775            /gnu/store

	keepdir                /var/guix/profiles/per-user
	fperms 1777            /var/guix/profiles/per-user

	newinitd "${FILESDIR}"/guix-daemon.initd guix-daemon

	guile_unstrip_ccache
}

pkg_postinst() {
	readme.gentoo_print_elog
}
