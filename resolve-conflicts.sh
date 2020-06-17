#!/usr/bin/env bash
#
#            _____                    _____                    _____
#           /\    \                  /\    \                  /\    \
#          /::\    \                /::\    \                /::\    \
#         /::::\    \              /::::\    \              /::::\    \
#        /::::::\    \            /::::::\    \            /::::::\    \
#       /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \
#      /:::/__\:::\    \        /:::/__\:::\    \        /:::/  \:::\    \
#      \:::\   \:::\    \      /::::\   \:::\    \      /:::/    \:::\    \
#    ___\:::\   \:::\    \    /::::::\   \:::\    \    /:::/    / \:::\    \
#   /\   \:::\   \:::\    \  /:::/\:::\   \:::\____\  /:::/    /   \:::\    \
#  /::\   \:::\   \:::\____\/:::/  \:::\   \:::|    |/:::/____/     \:::\____\
#  \:::\   \:::\   \::/    /\::/   |::::\  /:::|____|\:::\    \      \::/    /
#   \:::\   \:::\   \/____/  \/____|:::::\/:::/    /  \:::\    \      \/____/
#    \:::\   \:::\    \            |:::::::::/    /    \:::\    \
#     \:::\   \:::\____\           |::|\::::/    /      \:::\    \
#      \:::\  /:::/    /           |::| \::/____/        \:::\    \
#       \:::\/:::/    /            |::|  ~|               \:::\    \
#        \::::::/    /             |::|   |                \:::\    \
#         \::::/    /              \::|   |                 \:::\____\
#          \::/    /                \:|   |                  \::/    /
#           \/____/                  \|___|                   \/____/
#
#
#
# syncthing-resolve-conflicts
#
# Script for deleting duplicate "*sync-conflict*" files created by Syncthing.
#
# Usage:
#   ./resolve-conflicts.sh <directory>
#
# Depends on:
#  find
#
# Syncthing Resolve Conflicts: https://github.com/digital-engineering/syncthing-resolve-conflicts
#
# GNUv3 Public License

# Description #################################################################
#
# **syncthing-resolve-conflicts** is a bash script that uses the Unix `find`
# utility to locate files matching the pattern "*sync-conflict*". For each
# `sync-conflict` file that is found, the corresponding non-conflict file is
# matched. Then the sha256sum of each file in the pair is calculated. If the
# sums are equal, the redundant `sync-conflict` file is deleted. Otherwise, a
# message is shown so the user can investigate manually.

#
# Background #################################################################
#
# Syncthing tends create lots of `*sync-conflict*` files when there are sync
# issues, such as when trying to re-sync an entire 1T+ collection. Usually,
# these `sync-conflict` files can be deleted, but it can take a lot of work to
# locate and verify they can be deleted.
#
# This bash script employs the Unix `find` command to call the custom
# `__dResolveSyncthingConflict()` function. That function parses the sync_conflict_file_name,
# finds the original file, runs sha256sum on both of them, and deletes the
# `sync-conflict` file if they match. Otherwise, it emits an error message,
# allowing you to investigate manually.
#

# Safer programming env
set -euo pipefail

# Set color constants
__CLEAR='\033[0m'
__RED='\033[0;31m'

# Usage / help screen
function __usage() {
  if [ ! -z "${1-}" ] && [ -n "$1" ]; then
    echo -e "${__RED}👉 $1${__CLEAR}\n"
  fi
  echo "Usage: $0 [-h|--help] [-n|--dry-run] <directory>"
  echo ""
  echo "  -h, --help         This help screen"
  echo "  -n, --dry-run      Don't delete anything"
  echo ""
  echo "Example: $0 ~/Sync/"
  exit 1
}

###############################################################################
# Callback function passed to `find`. Compare sync-conflict file to original. #
###############################################################################
function __dResolveSyncthingConflict() {
  local dry_run="$2" # 0 or 1

  local sync_conflict_file_path="$1"
  local sync_conflict_file_name
  sync_conflict_file_name=$(basename -- "$sync_conflict_file_path")  # complete sync_conflict_file_name + ext
  local sync_conflict_file_base_name="${sync_conflict_file_name%.*}" # base sync_conflict_file_name without extension

  local file_ext="${sync_conflict_file_name##*.}"                    # original & sync_conflict_file_name extension

  local original_file_base_name="${sync_conflict_file_base_name%.*}" # original basename
  local original_file_base_path
  original_file_base_path=$(dirname -- "$sync_conflict_file_path") # base original_file_base_path
  local original_file_name="$original_file_base_name.$file_ext"
  local original_file_path="$original_file_base_path/$original_file_name"

  if [ ! -f "$original_file_path" ]; then
    echo -e "Could not find $original_file_name.\n"
    return
  fi

  echo -e "Path: '$original_file_base_path'\n"
  echo "Generating SHA256 sums..."

  local sha256
  local sha256orig
  sha256=$(sha256sum "$sync_conflict_file_path" | cut -f 1 -d ' ')
  sha256orig=$(sha256sum "$original_file_path" | cut -f 1 -d ' ')

  local filenameLen=${#sync_conflict_file_name}

  printf "%-${filenameLen}s $sha256orig\n" "$original_file_name"
  printf "%-${filenameLen}s $sha256\n" "$sync_conflict_file_name"

  if [[ "$sha256" == "$sha256orig" ]]; then
    # files the same
    echo -e "Equal: deleting $sync_conflict_file_name...\n"
    if [ "$dry_run" -eq "0" ]; then
      rm "$sync_conflict_file_path"
    fi
  else
    echo -e "MISMATCH: skipping...\n"
  fi
}

###############################################################################
# Main
###############################################################################

function __main() {
  local base_dir=""
  local dry_run=0 # default remove files

  # parse parameters
  if [ -z "${1-}" ]; then
    echo -e "${__RED}👉 Please provide directory${__CLEAR}\n"
    __usage
    exit 1
  fi

  while [[ "$#" -gt 0 ]]; do
    __opt="$1"
    shift
    case "$__opt" in
    -h | --help)
      __usage
      exit 1
      ;;
    -n | --dry-run)
      dry_run=1
      ;;
    *)
      if [[ -z "$base_dir" ]]; then
        # The first non-option argument is assumed to be the directory name.
        base_dir="$__opt"
      else
        __usage "$__opt"
        exit 1
      fi
      ;;
    esac
  done

  # get directory parameter from user input (remove trailing dir slash), or
  # default to current dir (.)
  local resolve_dir
  resolve_dir=$([[ -z "$base_dir" ]] && echo '.' || echo "${base_dir%/}")

  # find sync-conflicts, run __dResolveSyncthingConflict
  echo ""
  local find_cmd="__dResolveSyncthingConflict \"\$0\" $dry_run"
  find "$resolve_dir" -name '*sync-conflict*' \
    -not -path "$resolve_dir/.stversions/*" \
    -exec bash \
    -c "$find_cmd" {} \;
}

# Entry point
export -f __dResolveSyncthingConflict
__main "$@"
