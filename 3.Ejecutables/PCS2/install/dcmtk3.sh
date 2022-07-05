#!/bin/bash

ADMIN=$1
ORG=$2
BRANCH=$3

# system

echo "/Users/Shared/dcmtk/storescp/install.sh $ADMIN $BRANCH 4096"
/Users/Shared/dcmtk/storescp/install.sh "$ADMIN" "$BRANCH" 4098

echo "/Users/Shared/dcmtk/wlmscpfs/install.sh $ADMIN $BRANCH 11112 $ORG"
/Users/Shared/dcmtk/wlmscpfs/install.sh "$ADMIN" "$BRANCH" 11114 "$ORG"
