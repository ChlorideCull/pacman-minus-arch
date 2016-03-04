#!/bin/sh
pkgver=5.0.1
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
echo "--> Binaries will be placed in ${pkgdir}."
if [ -n "$MACHINEREADABLE" ]; then
	echo "PKGDIR: ${pkgdir}"
	echo "PKGVER: ${pkgver}"
fi
mkdir ${pkgdir}
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
make DESTDIR="${pkgdir}" install
make DESTDIR="${pkgdir}" -C contrib install
echo "--> pacman version ${pkgver} has been built."
if [ -n "$NOARCHLINUX" ]; then
	echo "--> not creating arch linux specifics."
	echo "--> done!"
	exit 0
fi
echo "--> creating arch linux mirrorlist."
mkdir -p "${pkgdir}/etc/pacman.d"
curl 'https://www.archlinux.org/mirrorlist/all/?country=all&protocol=http&protocol=https&ip_version=6' | sed 's/^\#Server/Server/g' > "${pkgdir}/etc/pacman.d/mirrorlist"
echo "--> fetching arch linux keyring."
keyringver=20160215
add_valid_sig archlinux-keyring 4AA4767BBC9C4B1D18AE28B77F2D434B9741E8AC # Pierre
add_valid_sig archlinux-keyring A314827C4E4250A204CE6E13284FC34C8E4B1A25 # Thomas
add_valid_sig archlinux-keyring 86CFFCA918CF3AF47147588051E8B148A9999C34 # Evangelos
dl_and_check_sig archlinux-keyring $keyringver
cd archlinux-keyring-${keyringver}
make PREFIX=/usr DESTDIR="${pkgdir}" install
cd "$pkgdir"
echo "--> patching pacman.conf"
echo "$pacmanpatch" | patch "${pkgdir}/etc/pacman.conf"
echo "--> done!"
echo "--> before syncing repos or installing anything, run"
echo "-->    pacman-key --init && pacman-key --populate archlinux"
echo "--> as root to initialize the keychain."

