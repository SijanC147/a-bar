#!/bin/zsh
# Copy only the built a-bar.app bundle to the checkout root.
# DerivedData (object files, modules, and the original bundle) stays put.
# Dry-run is the default. The Xcode scheme passes --apply.

emulate zsh
setopt errexit nounset pipefail

apply=0

while (( $# > 0 )); do
  case $1 in
    --apply)
      apply=1
      ;;
    --dry-run)
      apply=0
      ;;
    -h|--help)
      print -r -- "Usage: copy-app-to-checkout.sh [--apply|--dry-run]"
      print -r -- "Copies \$BUILT_PRODUCTS_DIR/a-bar.app to \$SRCROOT/a-bar.app."
      print -r -- "Default is dry-run and changes nothing. --apply replaces the checkout bundle."
      exit 0
      ;;
    *)
      print -ru2 -- "unknown option: $1"
      exit 2
      ;;
  esac
  shift
done

# GitHub Actions sets both. Leave that runner on its normal DerivedData path.
if [[ -n ${CI:-} || -n ${GITHUB_ACTIONS:-} ]]; then
  print -r -- "CI detected; leaving the built app in DerivedData."
  exit 0
fi

if [[ ${ACTION:-} == clean ]]; then
  print -r -- "clean; not copying a-bar.app."
  exit 0
fi

srcroot=${SRCROOT:-}
if [[ -z $srcroot ]]; then
  srcroot=${0:A:h:h}
fi
srcroot=${srcroot%/}

built=${BUILT_PRODUCTS_DIR:-}
built=${built%/}
if [[ -z $built ]]; then
  print -ru2 -- "BUILT_PRODUCTS_DIR is required."
  exit 1
fi

source="$built/a-bar.app"
dest="$srcroot/a-bar.app"

if [[ -z $srcroot || $srcroot == / || ${dest:t} != a-bar.app || ${dest:h} != $srcroot ]]; then
  print -ru2 -- "refusing to copy: destination must be the checkout a-bar.app."
  exit 1
fi

if [[ $source == $dest ]]; then
  print -ru2 -- "refusing to copy: source and destination are the same path."
  exit 1
fi

if [[ ! -d $source ]]; then
  print -ru2 -- "built app not found: $source"
  exit 1
fi

if (( apply )); then
  rm -rf -- "$dest"
  /usr/bin/ditto "$source" "$dest"
  print -r -- "copied $source -> $dest"
else
  print -r -- "dry-run: would remove $dest"
  print -r -- "dry-run: would copy $source -> $dest"
fi
