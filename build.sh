#!/usr/bin/bash
main() {
    set -e
    local Black DarkGray Red LightRed Green LightGreen Brown Yellow Blue LightBlue Purple Light Purple Cyan LightCyan LightGray White reset
    ## Save colors
    Black="\e[0;30m"
    DarkGray="\e[1;30m"
    Red="\e[0;31m"
    LightRed="\e[1;31m"
    Green="\e[0;32m"
    LightGreen="\e[1;32m"
    Brown="\e[0;33m"
    Yellow="\e[1;33m"
    Blue="\e[0;34m"
    LightBlue="\e[1;34m"
    Purple="\e[0;35m"
    Light=Purple="\e[1;35m"
    Cyan="\e[0;36m"
    LightCyan="\e[1;36m"
    LightGray="\e[0;37m"
    White="\e[1;37m"
    reset="\e[0m"
    local reponame
    reponame=${PWD##*/}
    
    echo -e "$Green### Start install packages for build $reponame ###$reset"
    echo -e "$Brown### Checking your OS ###$reset"
    if type pacman >/dev/null 2>&1;then
        if [ "$(id -u)" != "0" ]; then
            echo -e "$Red### You are not in root$reset"
            exit 1
        else
            install
            echo -e "$Blue### Install complete ###$reset"
            echo -e "$Green### Start build $reponame with archiso ###$reset"
	    build
        fi
    else
        echo -e "$Red###OS can't supported###$reset"
        exit 1
    fi

}

install() {
    set -e
    pacman -Sy; pacman --noconfirm -S --needed git wget github-cli p7zip reflector rsync
    wget https://git.parchlinux.com/repos/ppr/raw/branch/main/x86_64/archiso-99-1-any.pkg.tar.zst
    sudo pacman -U archiso-99-1-any.pkg.tar.zst --noconfirm
}


build() {
    set -e
    mkarchiso -v iso/
}


main
