#!/usr/bin/env bash


[[ "$1" == "source" ]] || \

echo 'DotManager - Ali "Ashkan" Dorostkar'

if [[ "$1" == "-h" || "$1" == "--help" ]]; 
then 
cat <<HELP

Usage: $(basename "$0")

See the README for documentation.
https://github.com/ashkan2200/dotmgr

HELP
exit; 
fi

###########################################
# GENERAL PURPOSE EXPORTED VARS / FUNCTIONS
###########################################

# Test if the dotmgr script is currently
function is_dotmgr_running() {
    [[ "$DOTMGR_SCRIPT_RUNNING" ]] || return 1
}

# Test if this script was run via the "dotmgr" bin script (vs. via curl/wget)
function is_dotmgr_bin() {
    [[ "$(basename $0 2>/dev/null)" == dotmgr ]] || return 1
}


# Where the magic happens.
# if not already set, set it as the folowing
export DOTMGR=${DOTMGR:-~/.dotmgr}
DOTMGR_GH_BRANCH=${DOTMGR_GH_BRANCH:-master}
DOTMGR_GH_USER=${DOTMGR_GH_USER:-ashkan2200}
BACKUP_DIR="$HOME/.cache/dotmgr/backups/$(date "+%Y_%m_%d-%H_%M_%S")/"
CACHE_DIR="$HOME/.cache/dotmgr/cache/"
# TODO: Need to update this to point into .local/share/...
MAN_DIR="$HOME/.cache/dotmgr/man/" 
# TODO: should we pass and install directory to .local/ or some other place if an script needs it?
DOTMGR_SCRIPT_RUNNING=1

function cleanup {
    unset DOTMGR_SCRIPT_RUNNING
    unset prompt_delay
}
trap cleanup EXIT

SUDO=$(type -P sudo)
if [[ "$SUDO" == "" ]]
then
    e_error "No sudo found, trying to continue without it"
fi


# Set the prompt delay to be longer for the very first run.
export prompt_delay=5 is_dotmgr_bin || prompt_delay=15

# Ensure that we can actually, like, compile anything.
if [[ ! "$(type -P gcc)" ]] && is_osx; then
    e_error "XCode or the Command Line Tools for XCode must be installed first."
    exit 1
fi

# If Git is not installed, install it (Ubuntu only, since Git comes standard
# with recent XCode or CLT)
if [[ ! "$(type -P git)" ]] && is_ubuntu; then
    e_header "Installing Git"
    ${SUDO} apt-get -qq install git-core &> /dev/null
fi

# If Git isn't installed by now, something exploded. We gots to quit!
if [[ ! "$(type -P git)" ]]; then
    e_error "Git should be installed. It isn't. Aborting."
    exit 1
fi

# # Initialize.
# if [[ ! -d $DOTMGR ]]; then
# 	# Dotmgr directory doesn't exist? Clone it!
# 	e_header "Downloading dotmgr"
# 	git clone --branch ${DOTMGR_GH_BRANCH} --recursive \
# 		git://github.com/${DOTMGR_GH_USER}/dotmgr.git $DOTMGR
# 	cd $DOTMGR
# elif [[ "$1" != "restart" ]]; then
# 	# Make sure we have the latest files.
# 	e_header "Updating dotmgr"
# 	cd $DOTMGR
# 	prev_head="$(git rev-parse HEAD)"
# 	git pull
# 	git submodule update --init --recursive --quiet
# 	if [[ "$(git rev-parse HEAD)" != "$prev_head" ]]; then
# 	if is_dotmgr_bin; then
# 		e_header "Changes detected, restarting script"
# 		exec "$0" restart
# 	else
# 		e_header "Changes detected, please re-run script"
# 		exit
# 	fi
# 	fi
# fi



# Source shared folder, everything that is needed for this
# script and will be sourced in every shell after setups
for f in ./shared/*
do
    echo "sourcing $f"
    source $f
done

# Get every folder that has install.sh in it under current directory
# this automatically omits any folder that this script has to be aware of
modules=$(find . -mindepth 2 -maxdepth 2 -name "install.sh" -printf "%h\n")
if [ "$modules" == "" ]; then
    e_error "No module to process"
    exit 0
fi

# make the pattern to auto select most appropriate submodules
oses=($(get_os 1))
ptrn="(^[^a-z]("
for os in "${oses[@]}"; do
    ptrn="${ptrn}$os|"
done
ptrn="${ptrn::-1})($|[^a-z])"


# Where to place the install cache
dotfile_cachedir=$HOME/.cache/dotmgr/install_cache.txt
# folders=($(filter_files $modules $ptrn $dotfile_cachedir $prompt_delay))
folders=($(filter_files "$modules" "$ptrn" "./cache.txt" "$prompt_delay"))
for d in "${folders[@]}"; do
    e_arrow "Processing $d"
    $d/install.sh --cache-prefix ${CACHE_DIR} --backup-prefix ${BACKUP_DIR}
	--man-prefix ${MAN_DIR}
done
