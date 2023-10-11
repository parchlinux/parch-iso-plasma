#!/usr/bin/bash
main() {
    set -e
    local Black DarkGray Red LightRed Green LightGreen Brown Yellow Blue LightBlue Purple Light Purple Cyan LightCyan LightGray White reset
    ## save colors
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
    
    echo -e "$Green### start install packeges for build $reponame ###$reset"
    echo -e "$Brown### checking your os ###$reset"
    if type pacman >/dev/null 2>&1;then
        if [ "$(id -u)" != "0" ]; then
            echo -e "$Red### you are not in root$reset"
            exit 1
        else
            install
            echo -e "$Blue### install complete ###$reset"
            echo -e "$Green### start build $reponame with archiso ###$reset"
            build
            makezip
        fi
    else
        echo -e "$Red###os cant supported###$reset"
        exit 1
    fi

}
install() {
    set -e
    pacman -Sy; pacman --noconfirm -S --needed git archiso github-cli p7zip
}
build() {
    set -e
    mkarchiso -v iso/
}
makezip() {
    cd out
    7z -v500m a "$(ls *.iso)".zip "$(ls *.iso)"
    md5sum * > md5sums.txt
}


main
