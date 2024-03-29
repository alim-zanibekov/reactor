#!/usr/bin/env bash

DIRECTORY=$(cd $(dirname $0) && pwd)
p1="$(dirname $(dirname $(readlink $(which flutter) 2>/dev/null || which flutter)))/packages/flutter/lib/src/widgets/editable_text.dart"
p2="$DIRECTORY/editable_text.dart.patch"

if [ "$1" == "r" ];
then
  if ! patch --dry-run -s -f $p1 $p2 >/dev/null; then
    patch -R $p1 $p2
    echo "rolled back"
  fi
else
  if ! patch -R --dry-run -s -f $p1 $p2 >/dev/null; then
    patch $p1 $p2
    echo "patched"
  fi
fi
