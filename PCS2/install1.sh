#!/bin/bash
admin=$1
org=$2
branch=$3

cd "$(dirname $0)"

cp -R dcmtk opendicom pass.sh start_all.sh stop_all.sh STORE /Users/Shared

cp -R RECEIVE /Volumes/IN/$branch

mkdir ~/Documents/{dcmtk,opendicom}

./install/dcmtk1.sh "$admin" "$org" "$branch"

cd "$(dirname $0)"
./install/opendicom1.sh "$admin" "$org" "$branch"
