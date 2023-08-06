#!/bin/bash
admin=$1
org=$2
branch=$3

cd "$(dirname $0)"
./dcmtk/storescp/install.sh "$admin" "$branch" 4098
./dcmtk/wlmscpfs/install.sh "$admin" "$branch" 11114 "$ORG"
