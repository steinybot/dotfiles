#!/usr/bin/env bash
set -euo pipefail

# Ever move a file, merge main, then get hit with this?
#
# Deleted merge conflict for 'foo.txt':
#   {local}: deleted
#   {remote}: modified file
# Use (m)odified or (d)eleted file, or (a)bort?
#
# This script lets you merge across renames and/or splits.
#
# Usage:
#
# git-mergetool-moved <commit> <remote_path> <local_path>
#
# Example: foo.txt was split into bar.txt and baz.txt
#
# git-mergetool-moved origin/main foo.txt bar.txt
# git-mergetool-moved origin/main foo.txt baz.txt
#
# NOTE: Don't forget to press (d) on that pesky delete merge conflict and carry on.

# 'commit' to merge into the current branch.
branch="$1"
# 'path' of the file on 'branch' and the merge base of 'branch' and the current branch.
original="$2"
# Path of the file in the working tree.
ours="$3"

temp_dir="$(mktemp -d)"
trap 'rm -rf -- "${temp_dir}"' EXIT

original_basename="$(basename "${original}")"

theirs="${temp_dir}/${original_basename}_THEIRS"
git show "${branch}:${original}" > "${theirs}"

merge_base="$(git merge-base "${branch}" HEAD)"
base="${temp_dir}/${original_basename}_BASE"
git show "${merge_base}:${original}" > "${base}"

bcomp "${ours}" "${theirs}" "${base}" "${ours}"
