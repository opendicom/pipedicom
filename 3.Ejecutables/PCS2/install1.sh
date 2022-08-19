#!/bin/bash
admin=$1
org=$2
branch=$3

#cp -R dcmtk opendicom pass.sh start_all.sh stop_all.sh /Users/Shared

cd "$(dirname $0)"
./install/dcmtk1.sh "$admin" "$org" "$branch"

cd "$(dirname $0)"
#./install/opendicom1.sh "$admin" "$org" "$branch"
