#!/bin/sh
# j o k e s
echo "pacman - arch + arch = pacman"
echo "so idk why you're using this"
echo "but fuck it, sure, we'll just use the real deal"
sudo pacman -Syu --needed abs base-devel
sudo abs core/pacman
tmpdir=$(mktemp -d)
cd $tmpdir
cp -r /var/abs/core/pacman .
cd pacman
makepkg -s

