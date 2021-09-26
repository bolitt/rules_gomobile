#!/bin/bash
# bash third_party/patch/patch_example/patch-BUILD.bazel.bash

# Step 1. Copy target file to this folder.
# cp <some/file/to/patch> "third_party/patch/patch_example/patch-BUILD.bazel.old"

# Step 2. Edit `patch-BUILD.bazel.old` and save to `patch-BUILD.bazel.new`

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR?}

# Step 3. Create a patch.
target="all.patch"

function add_patch() {
  local old_file="$1"
  local new_file="$2"
  local old_name="$3"
  local new_name="$4"

  # Diff and replace file names.
  # 
  # git diff --no-index "$old_file" "$new_file" | \
  #   sed -e "s#a/$old_file#a/$old_name#g" -e "s#b/$new_file#b/$new_name#g" | \
  #   tee -a $target
  diff -Naur "$old_file" "$new_file" | \
    sed -e "s#--- $old_file#--- $old_name#g" -e "s#+++ $new_file#+++ $new_name#g" | \
    tee -a $target
}

function main() {
  rm $target
  # In order: old_file, new_file, old_name, new_name,
  # add_patch "codereview.cfg.old" "codereview.cfg.new" "codereview.cfg" "codereview.cfg"
  add_patch "bind/BUILD.bazel.old" "bind/BUILD.bazel.new" "bind/BUILD.bazel" "bind/BUILD.bazel"
  add_patch "bind/java/BUILD.bazel.old" "bind/java/BUILD.bazel.new" "bind/java/BUILD.bazel" "bind/java/BUILD.bazel"
  add_patch "bind/objc/BUILD.bazel.old" "bind/objc/BUILD.bazel.new" "bind/objc/BUILD.bazel" "bind/objc/BUILD.bazel"
}

main

# Step 4. Edit file names in `patch-BUILD.bazel`.

# Step 5. Add the patch to WORKSPACE or repositories.bzl as `patches`
# The path label looks like: "//third_party/patch/patch_example:patch-BUILD.bazel.bash"
