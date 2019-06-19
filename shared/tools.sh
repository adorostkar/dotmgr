#!/usr/bin/env bash
# A set of tools usefull for various tasks

# Logging stuff.
MARK_OK="\033[1;32m✔\033[0m"
MARK_NOK="\033[1;31m✖\033[0m"
MARK_DO="\033[1;34m➜\033[0m"

function e_header()   { printf "\n\033[1m$@\033[0m\n"; }
function e_success()  { printf " %b $@\n" $MARK_OK; }
function e_error()    { printf " %b $@\n" $MARK_NOK; }
function e_arrow()    { printf " %b $@\n" $MARK_DO; }


# OS detection
function is_osx() {
  [[ "$OSTYPE" =~ ^darwin ]] || return 1
}
function is_ubuntu() {
  local DISTRO
  DISTRO=$( cat /etc/*release 2> /dev/null | grep -Poi -m 1 '(Ubuntu|Mint)' )
  [[ "${DISTRO}" =~ "" ]] || return 1
}
function is_ubuntu_desktop() {
  dpkg -l ubuntu-desktop >/dev/null 2>&1 || return 1
}
function get_os() {
  for os in osx ubuntu ubuntu_desktop; do
    is_$os; [[ $? == ${1:-0} ]] && echo $os
  done
}

# Remove an entry from $PATH
# Based on http://stackoverflow.com/a/2108540/142339
function path_remove() {
  local arg path
  path=":$PATH:"
  for arg in "$@"; do path="${path//:$arg:/:}"; done
  path="${path%:}"
  path="${path#:}"
  echo "$path"
}

# Display a fancy multi-select menu.
# Inspired by http://serverfault.com/a/298312
# @brief if there is a menu_options array in the current bash defined, This method 
#   prints the array with the header as the first input argument. It waits for a 
#    user key for the amount of time given in the second argument and if a key is 
#    is pressed the user can select/deselect options
#    The items in the menu_selects are selected by default. In the end the selection
#    is returned in the same array
# @param $1 the title of the menu
# @param $2 (optional) the amount of time to wait
function prompt_menu(){
  # Set selected choices for the rest of the algorithm and clear the choices 
  for i in "${!menu_options[@]}"; do
    for j in "${!menu_selects[@]}"; do
      [[ "${menu_selects[j]}" == "${menu_options[i]}" ]] && choices[i]=$MARK_OK && break
    done
  done
  menu_selects=()
  # If a time is specified then show a timeout menu
  prompt="Check an option (again to uncheck, ENTER when done): "
  if [[ "$2" ]]; then
   draw_menu "$1"
   read -t $2 -n 1 -sp "Press ENTER or wait $2 seconds to continue, or press any other key to edit."
   exitcode=$?
   echo ""
  fi 1>&2
  # if the menu should be edited then show edit options
  if [[ "$exitcode" == 0 && "$REPLY" ]]; then
   while draw_menu $1 && read -rp "$prompt" num && [[ "$num" ]]; do
    for n in  ${num[@]}; do
        [[ "$n" != *[![:digit:]]* ]] &&
          (( n > 0 && n <= ${#menu_options[@]} )) ||
          { __error_msg="Invalid option: $n"; continue; }
          ((n--)); 
          [[ "${choices[n]}" ]] && choices[n]="" || choices[n]=$MARK_OK
        done
      done
  fi 1>&2

  # gather all the selected options in the same place
  menu_selects=()
  for i in ${!menu_options[@]}; do
    [[ "${choices[i]}" ]] && menu_selects=("${menu_selects[@]}" "${menu_options[i]}") 
  done
  # echo "${menu_selects[@]}"
}

function draw_menu() {
    echo $1
    for i in ${!menu_options[@]}; do
        printf " %b%3d) %s\n" "${choices[i]:-$MARK_NOK}" $((i+1)) "${menu_options[i]}"
    done
    [[ "$__error_msg" ]] && echo "$__error_msg"; :
}

# Array filter. Calls filter_fn for each item ($1) and index ($2) in array_name
# array, and prints all values for which filter_fn returns a non-zero exit code
# to stdout. If filter_fn is omitted, input array items that are empty strings
# will be removed.
# Usage: array_filter array_name [filter_fn]
# Eg. mapfile filtered_arr < <(array_filter source_arr)
function array_filter() { __array_filter 1 "$@"; }
# Works like array_filter, but outputs array indices instead of array items.
function array_filter_i() { __array_filter 0 "$@"; }
# The core function. Wheeeee.
function __array_filter() {
  local __i__ __val__ __mode__ __arr__
  __mode__=$1; shift; __arr__=$1; shift
  for __i__ in $(eval echo "\${!$__arr__[@]}"); do
    __val__="$(eval echo "\${$__arr__[__i__]}")"
    if [[ "$1" ]]; then
      "$@" "$__val__" $__i__ >/dev/null
    else
      [[ "$__val__" ]]
    fi
    if [[ "$?" == 0 ]]; then
      if [[ $__mode__ == 1 ]]; then
        eval echo "\"\${$__arr__[__i__]}\""
      else
        echo $__i__
      fi
    fi
  done
}

# Given strings containing space-delimited words A and B, "setdiff A B" will
# return all words in A that do not exist in B. Arrays in bash are insane
# (and not in a good way).
# From http://stackoverflow.com/a/1617303/142339
function setdiff() {
  local debug skip a b
  if [[ "$1" == 1 ]]; then debug=1; shift; fi
  if [[ "$1" ]]; then
    local setdiff_new setdiff_cur setdiff_out
    setdiff_new=($1); setdiff_cur=($2)
  fi
  setdiff_out=()
  for a in "${setdiff_new[@]}"; do
    skip=
    for b in "${setdiff_cur[@]}"; do
      [[ "$a" == "$b" ]] && skip=1 && break
    done
    [[ "$skip" ]] || setdiff_out=("${setdiff_out[@]}" "$a")
  done
  [[ "$debug" ]] && for a in setdiff_new setdiff_cur setdiff_out; do
    echo "$a ($(eval echo "\${#$a[*]}")) $(eval echo "\${$a[*]}")" 1>&2
  done
  [[ "$1" ]] && echo "${setdiff_out[@]}"
}

# This function is not general enough to be sourced
# Look into a directory that is passed to the function and decide which should be
# included in the output (shows green ticks next to them)
# show a menu that can be edited and return the selected options.
# the selection is saved into cache file
# needs two inputs, 1) a list of files and folders 2) the matching pattern 3) where the cache should be saved 4) the prompt delay
function filter_files() {
  local i f matching_pattern cache_file pDelay dname oses os opt remove
  f=($1)
  matching_pattern=$2
  cache_file=$3
  pDelay=$4


  dname="$(dirname "$f[0]")"
  menu_options=(); menu_selects=()
  for i in "${!f[@]}"; do menu_options[i]="$(basename "${f[i]}")"; done
  if [[ -e "$cache_file" ]]; then
    # Read cache file if possible
    IFS=$'\n' read -d '' -r -a menu_selects < "$cache_file"
  else
    # Otherwise default to all scripts that do not match the pattern
    for opt in "${menu_options[@]}"; do
      remove=
      [[ "$opt" =~ ${matching_pattern} ]] && remove=1 && break
      [[ "$remove" ]] || menu_selects=("${menu_selects[@]}" "$opt")
    done
  fi
  prompt_menu "Select the following scripts?" $pDelay
  # Write out cache file for future reading.
  rm "$cache_file" 2>/dev/null
  for i in "${!menu_selects[@]}"; do
    echo "${menu_selects[i]}" >> "$cache_file"
    echo "$dname/${menu_selects[i]}"
  done
}

