# pacman-minus-arch
A repository of scripts to build packages of pacman and everything needed to talk to
Arch Linux repos, without actually being on Arch Linux. Useful for bootstrapping.

`make.sh` should work on any *nix as long as there's a sane dev environment and you've
got the basic dependencies installed:

* `pkg-config`
* OpenSSL (libcrypto)
* libarchive > 2.8.0
* libcurl

However, if there's a script for your distribution, like `make-ubuntu.sh`, you should
use that as it handles dependencies and generates packages for the package manager.
