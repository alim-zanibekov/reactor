#!/usr/bin/env bash

p1="$(dirname $(dirname $(which flutter)))/packages/flutter/lib/src/widgets/editable_text.dart"
p2=./editable_text.dart.patch

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
