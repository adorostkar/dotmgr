#!/usr/bin/env bash

# Write the correct path for these variable in order to make
# default paths
__INSTALL_PREFIX=/path/to/install/root
__CACHE_PREFIX=/path/to/cache/root
__BACKUP_PREFIX=/path/to/backup/root
__MAN_PREFIX=/path/to/man/root

help(){
cat<<HELP
Usage: $(basename $0) [option]

Options:
   -p/--prefix         : set prefix directory for install, cache and backup folder
   -i/--install-prefix: set prefix directory for install folder
   -c/--cache-prefix: set prefix directory for cache folder
   -b/--backup-prefix: set prefix directory for backup folder
   -m/--man-prefix: set prefix directory for backup folder
HELP
}

process_commands() {
# Process options and save positional target
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -p|--prefix)
            __INSTALL_PREFIX=$2
            __CACHE_PREFIX=$2
            __BACKUP_PREFIX=$2
            __MAN_PREFIX=$2
            shift 2 # past argument
            ;;
        -i|--install)
            __INSTALL_PREFIX=$2
            shift 2 # past argument
            ;;
        -c|--cache)
            __CACHE_PREFIX=$2
            shift 2 # past argument
            ;;
        -b|--backup)
            __BACKUP_PREFIX=$2
            shift 2 # past argument
            ;;
        -m|--man)
            __MAN_PREFIX=$2
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
    # check if the paths are non empty (if it is necessary
    # for the installation

}

if [ "$1" != "src" ]; then
    install $@
fi
