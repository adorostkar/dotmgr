#!/usr/bin/env bash

DOTFILES_INSTALL_PREFIX=${INSTALL_PREFIX:-/path/to/install/root}
DOTFILES_CACHE_PREFIX=${DOTFILES_CACHE_PREFIX:-/path/to/cache/root}
DOTFILES_BACKUP_PREFIX=${DOTFILES_BACKUP_PREFIX:-/path/to/backup/root}

help(){
cat<<HELP
Usage: $(basename $0) [option]

Options:
   -p/--prefix         : set prefix directory for install, cache and backup folder
   -i/--install-prefix : set prefix directory for install folder
   -c/--cache-prefix   : set prefix directory for cache folder
   -b/--backup-prefix  : set prefix directory for backup folder
HELP
}

process_commands() {
# Process options and save positional target
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-p|--prefix)
			DOTFILES_INSTALL_PREFIX=$2
			DOTFILES_CACHE_PREFIX=$2
			DOTFILES_BACKUP_PREFIX=$2
			shift 2 # past argument
			;;
		-i|--install-prefix)
			DOTFILES_INSTALL_PREFIX=$2
			shift 2 # past argument
			;;
		-c|--cache-prefix)
			DOTFILES_CACHE_PREFIX=$2
			shift 2 # past argument
			;;
		-b|--backup-prefix)
			DOTFILES_BACKUP_PREFIX=$2
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
