#!/bin/bash
ADMIN=$1
ORG=$2
BRANCH=$3

mkdir -m 775 -p "/Users/$ADMIN/Documents/opendicom"

coercedicom='/Users/'"$ADMIN"'/Library/LaunchAgents/coercedicom.'"$BRANCH"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $coercedicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $coercedicom
echo '<plist version="1.0">'                                                                                  >> $coercedicom
echo '<dict>'                                                                                                 >> $coercedicom
echo '    <key>Label</key>'                                                                                   >> $coercedicom
echo '    <string>coercedicom.'"$BRANCH"'</string>'                                                           >> $coercedicom
echo '    <key>ProgramArguments</key>'                                                                        >> $coercedicom
echo '    <array>'                                                                                            >> $coercedicom
echo '        <string>/usr/local/bin/coercedicom</string>'                                                    >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/CLASSIFIED</string>'                                            >> $coercedicom
echo '        <string>/Volumes/IN</string>'                                                                   >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/FAILURE</string>'                                               >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/ORIGINALS</string>'                                             >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/MISMATCH_ALTERNATES</string>'                                   >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/MISMATCH_SENDING</string>'                                       >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/MISMATCH_CDAMWL</string>'                                       >> $coercedicom
echo '        <string>/Volumes/IN/'"$BRANCH"'/MISMATCH_PACS</string>'                                         >> $coercedicom
echo '        <string>/Users/Shared/opendicom/coercedicom/'"$BRANCH"'/coercedicom.json</string>'              >> $coercedicom
echo '        <string>&quot;&quot;</string>'                                                                  >> $coercedicom
echo '        <string>&quot;&quot;</string>'                                                                  >> $coercedicom
echo '        <string>90</string>'                                                                            >> $coercedicom
echo '        <string>10</string>'                                                                             >> $coercedicom
echo '        <string>30</string>'                                                                            >> $coercedicom
echo '    </array>'                                                                                           >> $coercedicom
echo '    <key>StandardErrorPath</key>'                                                                       >> $coercedicom
echo '    <string>/Users/pcs2/Documents/opendicom/coercedicom.'"$BRANCH"'.error.log</string>'                 >> $coercedicom
echo '    <key>StandardOutPath</key>'                                                                         >> $coercedicom
echo '    <string>/Users/pcs2/Documents/opendicom/coercedicom.'"$BRANCH"'.log</string>'                       >> $coercedicom
echo '    <key>StartInterval</key>'                                                                           >> $coercedicom
echo '    <integer>120</integer>'                                                                             >> $coercedicom
echo '    <key>Umask</key>'                                                                                   >> $coercedicom
echo '    <integer>0</integer>'                                                                               >> $coercedicom
echo '</dict>'                                                                                                >> $coercedicom
echo '</plist>'                                                                                               >> $coercedicom


cleanOriginals='/Users/'"$ADMIN"'/Library/LaunchAgents/cleanOriginals.'"$BRANCH"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $cleanOriginals
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $cleanOriginals
echo '<plist version="1.0">'                                                                                  >> $cleanOriginals
echo '<dict>'                                                                                                 >> $cleanOriginals
echo '    <key>Label</key>'                                                                                   >> $cleanOriginals
echo '    <string>cleanOriginals.'"$BRANCH"'</string>'                                                        >> $cleanOriginals
echo '    <key>ProgramArguments</key>'                                                                        >> $cleanOriginals
echo '    <array>'                                                                                            >> $cleanOriginals
echo '        <string>/Users/Shared/opendicom/coercedicom/cleanOriginals.sh</string>'                         >> $cleanOriginals
echo '        <string>/Volumes/IN/'"$BRANCH"'/ORIGINALS</string>'                                             >> $cleanOriginals
echo '        <string>7</string>'                                                                             >> $cleanOriginals
echo '        <string>https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE</string>'                      >> $cleanOriginals
echo '    </array>'                                                                                           >> $cleanOriginals
echo '    <key>StandardErrorPath</key>'                                                                       >> $cleanOriginals
echo '    <string>/Users/pcs2/Documents/opendicom/cleanOriginals.'"$BRANCH"'.error.log</string>'              >> $cleanOriginals
echo '    <key>StandardOutPath</key>'                                                                         >> $cleanOriginals
echo '    <string>/Users/pcs2/Documents/opendicom/cleanOriginals.'"$BRANCH"'.log</string>'                    >> $cleanOriginals
echo '    <key>StartCalendarInterval</key>'                                                                   >> $cleanOriginals
echo '    <dict>'                                                                                             >> $cleanOriginals
echo '        <key>Hour</key>'                                                                                >> $cleanOriginals
echo '        <integer>1</integer>'                                                                           >> $cleanOriginals
echo '        <key>Minute</key>'                                                                              >> $cleanOriginals
echo '        <integer>0</integer>'                                                                           >> $cleanOriginals
echo '    </dict>'                                                                                            >> $cleanOriginals
echo '    <key>Umask</key>'                                                                                   >> $cleanOriginals
echo '    <integer>0</integer>'                                                                               >> $cleanOriginals
echo '</dict>'                                                                                                >> $cleanOriginals
echo '</plist>'                                                                                               >> $cleanOriginals


mkdir -m 775 -p /Users/Shared/opendicom/coercedicom/$BRANCH

ln -s "$coercedicom" "/Users/Shared/opendicom/coercedicom/$BRANCH/coercedicom.$BRANCH.plist"
ln -s "$cleanOriginals" "/Users/Shared/opendicom/coercedicom/$BRANCH/cleanOriginals.$BRANCH.plist"

json="/Users/Shared/opendicom/coercedicom/$BRANCH/coercedicom.json"
echo '[{ '                                                                                                  >  $json
echo '"regex":".*", '                                                                                       >> $json
echo '"removeFromDataset":[ "00000001_00101010-AS" ], '                                                     >> $json
echo '"coerceDataset":{ "00000001_00080080-LO":[ "'"$BRANCH"'" ]}, '                                        >> $json
echo '"supplementToDataset":{ "00000001_00081060-PN":[ "'"$BRANCH"'" ]}, '                                  >> $json
echo '"removeFromEUIDprefixedDataset":{ "2.16.858.2":[ "00000001_00081060-PN", "00000001_00081030-LO" ]}, ' >> $json
echo '"branch":"'"$BRANCH"'", '                                                                             >> $json
echo '"pacsAET":"'"$ORG"'", '                                                                               >> $json
echo '"j2kLayers":1 '                                                                                       >> $json
echo '}]'                                                                                                   >> $json

start='/Users/Shared/opendicom/coercedicom/'"$BRANCH"'/start.sh'
echo '#!/bin/sh'                                          >  $start
echo 'launchctl load -w '"$coercedicom"                   >> $start
echo 'launchctl load -w '"$cleanOriginals"                >> $start
echo 'launchctl list | grep "coercedicom.'"$BRANCH"'"'    >> $start
echo 'launchctl list | grep "cleanOriginals.'"$BRANCH"'"' >> $start
chmod 700 $start

stop='/Users/Shared/opendicom/coercedicom/'"$BRANCH"'/stop.sh'
echo '#!/bin/sh'                                          >  $stop
echo 'launchctl unload -w '"$coercedicom"                 >> $stop
echo 'launchctl unload -w '"$cleanOriginals"              >> $stop
echo 'launchctl list | grep "coercedicom.'"$BRANCH"'"'    >> $stop
echo 'launchctl list | grep "cleanOriginals.'"$BRANCH"'"' >> $stop
chmod 700 $stop
