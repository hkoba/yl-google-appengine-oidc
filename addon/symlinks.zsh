#!/bin/zsh

emulate -L zsh

set -e

realScriptFn=$(readlink -f $0)
addonDir=$realScriptFn:h
appDir=$addonDir:h

cd $appDir

for d in $addonDir/*(/); do
    (cd $d; find lib -mindepth 1 -type d -print)
done | sort | uniq | xargs mkdir -pv
    
for d in $addonDir/*(/); do
    (cd $d; find lib -mindepth 1 -type f -print) | while read fn; do
        ln -vnsfr $d/$fn $fn
    done
done
