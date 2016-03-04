#!/bin/sh
pkgver=5.0.1
# TODO: download core.db from an archlinux mirror, gunzip it, and tar tf with some grep and
#       sed to get the latest versions in use on stable.
tmpdir=$(mktemp -d)
pkgdir="${tmpdir}/pkgdata"
pacmanpatch="$(cat pacman.conf.patch)"

add_valid_sig() {
	mkdir -p "$tmpdir/.gpg${1}"
	chmod 700 "$tmpdir/.gpg${1}"
	GNUPGHOME="$tmpdir/.gpg${1}" gpg --keyserver keyserver.ubuntu.com --recv-keys ${2}
}

dl_and_check_sig() {
	wget https://sources.archlinux.org/other/${1}/${1}-${2}.tar.gz
	wget https://sources.archlinux.org/other/${1}/${1}-${2}.tar.gz.sig
	GNUPGHOME="$tmpdir/.gpg${1}" gpg --verify ${1}-${2}.tar.gz.sig
	if [ $? != 0 ]; then
		echo '--> /!\ Failed to verify with pgp key. Possibly tampered with?'
		exit 1
	else
		echo '--> PGP key verified download, continuing.'
	fi
}

echo "--> Building pacman version ${pkgver} in ${tmpdir}."
echo "--> Binaries will be placed in subdirectories of ${pkgdir}."
if [ -n "$MACHINEREADABLE" ]; then
	echo "PACMAN-PKGDIR: ${pkgdir}/pacman"
	echo "PACMAN-PKGVER: ${pkgver}"
fi
mkdir "${pkgdir}"
mkdir "$pkgdir/pacman"
cd $tmpdir
add_valid_sig pacman 6645B0A8C7005E78DB1D7864F99FFE0FEAE999BD # Signed by Allan
dl_and_check_sig pacman ${pkgver}
tar xf pacman-${pkgver}.tar.gz
cd pacman-${pkgver}
./configure --prefix=/usr --sysconfdir=/etc \
            --localstatedir=/var --enable-doc \
            --with-scriptlet-shell=/bin/bash \
            --with-ldconfig=/bin/ldconfig
make V=1
make -C contrib
make DESTDIR="$pkgdir/pacman" install
make DESTDIR="$pkgdir/pacman" -C contrib install
echo "--> pacman version ${pkgver} has been built."
echo "--> creating arch linux mirrorlist."
if [ -n "$MACHINEREADABLE" ]; then
	echo "MLIST-PKGDIR: ${pkgdir}/pacman-archlinux-mirrorlist"
	echo "MLIST-PKGVER: $(date +%Y%m%d)"
fi
mkdir -p "${pkgdir}/pacman-archlinux-mirrorlist/etc/pacman.d"
curl 'https://www.archlinux.org/mirrorlist/all/?country=all&protocol=http&protocol=https&ip_version=6' | sed 's/^\#Server/Server/g' > "${pkgdir}pacman-archlinux-mirrorlist/etc/pacman.d/mirrorlist"
echo "--> fetching arch linux keyring."
keyringver=20160215
# TODO: See TODO up top.
mkdir "$pkgdir/pacman-archlinux-keyring"
if [ -n "$MACHINEREADABLE" ]; then
	echo "KEYRING-PKGDIR: ${pkgdir}/pacman-archlinux-keyring"
	echo "KEYRING-PKGVER: ${keyringver}"
fi
add_valid_sig archlinux-keyring 4AA4767BBC9C4B1D18AE28B77F2D434B9741E8AC # Pierre
add_valid_sig archlinux-keyring A314827C4E4250A204CE6E13284FC34C8E4B1A25 # Thomas
add_valid_sig archlinux-keyring 86CFFCA918CF3AF47147588051E8B148A9999C34 # Evangelos
dl_and_check_sig archlinux-keyring $keyringver
cd archlinux-keyring-${keyringver}
make PREFIX=/usr DESTDIR="${pkgdir}/pacman-archlinux-keyring" install
cd "$pkgdir/pacman"
echo "--> patching pacman.conf"
echo "$pacmanpatch" | patch "${pkgdir}/etc/pacman.conf"
echo "--> done!"
echo "--> before syncing repos or installing anything, run"
echo "-->    pacman-key --init && pacman-key --populate archlinux"
echo "--> as root to initialize the keychain."

