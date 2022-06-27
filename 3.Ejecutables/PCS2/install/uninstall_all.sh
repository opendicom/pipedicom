#!/bin/sh

/Users/Shared/stop_all.sh

find /Users/Shared/dcmtk/storescp/* -type d -prune -exec rm -Rf {} \;
find /Users/Shared/dcmtk/wlmscpfs/* -type d -prune -exec rm -Rf {} \;

find /Users/Shared/opendicom/cdamwldicom/* -type d -prune -exec rm -Rf {} \;
find /Users/Shared/opendicom/coercedicom/* -type d -prune -exec rm -Rf {} \;
find /Users/Shared/opendicom/storedicom/* -type d -prune -exec rm -Rf {} \;

find /Users/pcs2/Documents/* -prune -exec rm -Rf {} \;

find /Volumes/IN/* -prune -exec rm -Rf {} \;

find /Users/pcs2/Library/LaunchAgents/* -prune -name 'cdamwldicom*' -exec rm -f {} \;
find /Users/pcs2/Library/LaunchAgents/* -prune -name 'olditems*' -exec rm -f {} \;
find /Users/pcs2/Library/LaunchAgents/* -prune -name 'coercedicom*' -exec rm -f {} \;
find /Users/pcs2/Library/LaunchAgents/* -prune -name 'storedicom*' -exec rm -f {} \;

find /Library/LaunchDaemons/* -prune -name 'storescp*' -exec rm -f {} \;
find /Library/LaunchDaemons/* -prune -name 'wlmscpfs*' -exec rm -f {} \;
