#!/bin/bash
# calls
# /Users/Shared/opendicom/coercedicom/cleanDevice.sh
# on all devices of $1


ds=$( ls $1 )
for d in $ds; do
   cd "$1/$d"
   /Users/Shared/opendicom/coercedicom/cleanDevice.sh
done
