# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

DESCRIPTION="Builder group for guix-daemon from sys-apps/guix"
# Upstream uses 30000, but it clashes with acct-group/nixbld
ACCT_GROUP_ID=31000
