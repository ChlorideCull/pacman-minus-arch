#!/bin/sh
echo "--> preparing build on ubuntu (assuming x86_64)"
echo "--> installing script prereqs"
sudo apt-get update
sudo apt-get --no-install-recommends install gnupg wget curl xz-utils
echo "--> installing package prereqs"
sudo apt-get --no-install-recommends install bash libc6-dev libarchive-dev libgpgme11-dev libcurl4-openssl-dev libssl-dev asciidoc
echo "--> installing basic compiling and packaging environment"
sudo apt-get --no-install-recommends install build-essential pkg-config
MACHINEREADABLE=y ./make.sh | tee make.log
echo "--> building .deb"
bindir=$(grep "PKGDIR: " make.log | sed 's/PKGDIR: //g')
pkgver=$(grep "PKGVER: " make.log | sed 's/PKGVER: //g')
pkgdir=$(mktemp -d)
cd "$bindir"
tar --owner=root --group=root -cf $pkgdir/data.tar.gz .
cd "$pkgdir"
echo "2.0" > debian-binary
mkdir control && cd control
tee control << EOF
Package: pacman
Version: ${pkgver}
Architecture: amd64
Maintainer: Chloride Cull <steamruler@gmail.com>
Depends: bash, libc6, libarchive13, curl, libgpgme11
Original-Maintainer: Allan McRae <allan@archlinux.org>
Origin: archlinux
EOF
tar --owner=root --group=root -cf ../control.tar control
cd ..
ar cq pacman-${pkgver}.deb debian-binary control.tar data.tar.gz
echo "--> a simple package is available at"
echo "-->    ${pkgdir}/pacman-${pkgver}.deb"
echo "--> it contains no scripts."

