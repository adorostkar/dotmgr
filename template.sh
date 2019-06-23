#!/usr/bin/env bash

TEMPLATE_INSTALL_PREFIX=${INSTALL_PREFIX:-/path/to/install/root}
TEMPLATE_CACHE_PREFIX=${TEMPLATE_CACHE_PREFIX:-/path/to/cache/root}
TEMPLATE_BACKUP_PREFIX=${TEMPLATE_BACKUP_PREFIX:-/path/to/backup/root}
TEMPLATE_MAN_PREFIX=${TEMPLATE_MAN_PREFIX:-/path/to/man/root}

help(){
cat<<HELP
Usage: $(basename $0) [option]

Options:
   -p/--prefix         : set prefix directory for install, cache and backup folder
   -i/--install: set prefix directory for install folder
   -c/--cache: set prefix directory for cache folder
   -b/--backup: set prefix directory for backup folder
   -m/--man: set prefix directory for backup folder
HELP
}

process_commands() {
# Process options and save positional target
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -p|--prefix)
            TEMPLATE_INSTALL_PREFIX=$2
            TEMPLATE_CACHE_PREFIX=$2
            TEMPLATE_BACKUP_PREFIX=$2
            TEMPLATE_MAN_PREFIX=$2
            shift 2 # past argument
            ;;
        -i|--install)
            TEMPLATE_INSTALL_PREFIX=$2
            shift 2 # past argument
            ;;
        -c|--cache)
            TEMPLATE_CACHE_PREFIX=$2
            shift 2 # past argument
            ;;
        -b|--backup)
            TEMPLATE_BACKUP_PREFIX=$2
            shift 2 # past argument
            ;;
        -m|--man)
            TEMPLATE_MAN_PREFIX=$2
            shift 2 # past argument
            ;;
        *)  # unknown option
            echo "Unknown option '"$1"'" 1>&2
            help
            exit 1
            ;;
    esac
done
}

# This is called by the dotfiles script
install() {
    process_commands $@

}

if [ "$1" != "src" ]; then
    install $@
fi
