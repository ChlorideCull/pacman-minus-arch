#!/bin/sh

build-deb() {
	echo "--> building .deb"
	tmpdir=$(mktemp -d)
	cd "$4"
	tar --owner=root --group=root -cf $tmpdir/data.tar.gz .
	cd "$tmpdir"
	echo "2.0" > debian-binary
	mkdir control && cd control
	tee control << EOF
Package: ${2}
Desc: ${2} from Arch Linux.
Version: ${3}
Architecture: amd64
Maintainer: Chloride Cull <steamruler@gmail.com>
${5}
Origin: archlinux
EOF
	tar --owner=root --group=root -cf ../control.tar control
	cd ..
	ar cq ${1}/${2}-${3}.deb debian-binary control.tar data.tar.gz
	echo "--> a simple package is available at"
	echo "-->    ${1}/${2}-${3}.deb"
	echo "--> it contains no scripts."
	cd "$4"
	rm -rf "$tmpdir"
}

echo "--> preparing build on ubuntu (assuming x86_64)"
echo "--> installing script prereqs"
sudo apt-get update
sudo apt-get --no-install-recommends install gnupg wget curl xz-utils
echo "--> installing package prereqs"
sudo apt-get --no-install-recommends install bash libc6-dev libarchive-dev libgpgme11-dev libcurl4-openssl-dev libssl-dev asciidoc
echo "--> installing basic compiling and packaging environment"
sudo apt-get --no-install-recommends install build-essential pkg-config
MACHINEREADABLE=y ./make.sh | tee make.log
makelog=$(cat make.log)
outdir=$(mktemp -d)

build-deb $outdir \
	"pacman" \
	$(echo "$makelog" | grep "PACMAN-PKGVER: " | sed 's/PACMAN-PKGVER: //g') \
	$(echo "$makelog" | grep "PACMAN-PKGDIR: " | sed 's/PACMAN-PKGDIR: //g') \
	"Depends: bash, libc6, libarchive13, libcurl4, libgpgme11, libssl, pacman-archlinux-mirrorlist"
build-deb $outdir \
	"pacman-archlinux-mirrorlist" \
	$(echo "$makelog" | grep "MLIST-PKGVER: " | sed 's/MLIST-PKGVER: //g') \
	$(echo "$makelog" | grep "MLIST-PKGDIR: " | sed 's/MLIST-PKGDIR: //g') \
	"Depends: pacman-archlinux-keyring"
build-deb $outdir \
	"pacman-archlinux-keyring"
	$(echo "$makelog" | grep "KEYRING-PKGVER: " | sed 's/KEYRING-PKGVER: //g') \
	$(echo "$makelog" | grep "KEYRING-PKGDIR: " | sed 's/KEYRING-PKGDIR: //g') \
	"# No Depends"

