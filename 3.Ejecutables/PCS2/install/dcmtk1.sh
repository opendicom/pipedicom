#!/bin/bash
admin=$1
org=$2
branch=$3

# system
cd "$(dirname $0)"
./dcmtk/storescp/install.sh "$admin" "$branch" 4096

#/Users/Shared/dcmtk/wlmscpfs/install.sh "$admin" "$branch" 11112 "$org"
