#!/usr/bin/env bash


[[ "$1" == "source" ]] || \

echo 'Dotfiles - Ali "Ashkan" Dorostkar'

if [[ "$1" == "-h" || "$1" == "--help" ]]; 
then 
cat <<HELP

Usage: $(basename "$0")

See the README for documentation.
https://github.com/ashkan2200/dotfiles

HELP
exit; 
fi

###########################################
# GENERAL PURPOSE EXPORTED VARS / FUNCTIONS
###########################################

# Test if the dotfiles script is currently
function is_dotfiles_running() {
  [[ "$DOTFILES_SCRIPT_RUNNING" ]] || return 1
}

# Test if this script was run via the "dotfiles" bin script (vs. via curl/wget)
function is_dotfiles_bin() {
  [[ "$(basename $0 2>/dev/null)" == dotfiles ]] || return 1
}


# Where the magic happens.
# if not already set, set it as the folowing
export DOTFILES=${DOTFILES:-~/.dotfiles}
DOTFILES_GH_BRANCH=${DOTFILES_GH_BRANCH:-master}
DOTFILES_GH_USER=${DOTFILES_GH_USER:-ashkan2200}
BACKUP_DIR="$HOME/.cache/dotfiles/backups/$(date "+%Y_%m_%d-%H_%M_%S")/"
CACHE_DIR="$HOME/.cache/dotfiles/cache/"
DOTFILES_SCRIPT_RUNNING=1
function cleanup {
  unset DOTFILES_SCRIPT_RUNNING
  unset prompt_delay
}
trap cleanup EXIT

SUDO=$(type -P sudo)
if [[ "$SUDO" == "" ]]
then
  e_error "No sudo found, trying to continue without it"
fi


# Set the prompt delay to be longer for the very first run.
export prompt_delay=5 is_dotfiles_bin || prompt_delay=15

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
# if [[ ! -d $DOTFILES ]]; then
#   # Dotfiles directory doesn't exist? Clone it!
#   e_header "Downloading dotfiles"
#   git clone --branch ${DOTFILES_GH_BRANCH} --recursive \
#     git://github.com/${DOTFILES_GH_USER}/dotfiles.git $DOTFILES
#   cd $DOTFILES
# elif [[ "$1" != "restart" ]]; then
#   # Make sure we have the latest files.
#   e_header "Updating dotfiles"
#   cd $DOTFILES
#   prev_head="$(git rev-parse HEAD)"
#   git pull
#   git submodule update --init --recursive --quiet
#   if [[ "$(git rev-parse HEAD)" != "$prev_head" ]]; then
#     if is_dotfiles_bin; then
#       e_header "Changes detected, restarting script"
#       exec "$0" restart
#     else
#       e_header "Changes detected, please re-run script"
#       exit
#     fi
#   fi
# fi
#


# TODO: source shared folder
for f in ./shared/*
do
	echo "sourcing $f"
	source $f
done

# Get every folder that has install.sh in it under current directory
# this automatically omits any folder that this script has to be aware of
modules=$(find . -mindepth 2 -maxdepth 2 -name "install.sh" -printf "%h\n")

# make the pattern to auto select most appropriate submodules
oses=($(get_os 1))
ptrn="(^[^a-z]("
for os in "${oses[@]}"; do
	ptrn="${ptrn}$os|"
done
ptrn="${ptrn::-1})($|[^a-z])"


# TODO change cache placement
folders=($(filter_files $modules $ptrn ./cache.txt $prompt_delay))
for d in "${folders[@]}"; do
	e_arrow "Installing $d"
	$d/install.sh --cache ${CACHE_DIR} --backup ${BACKUP_DIR} 
done
