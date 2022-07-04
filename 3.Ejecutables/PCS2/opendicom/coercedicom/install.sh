#!/bin/bash
if [ "$#" -ne 4 ]; then
   echo 'opendicom/coercedicom/install.sh'
   echo '$1= (admin)'
   echo '$2= (org)'
   echo '$3= (branch)'
else


#admin
su $1
#logs
if [ ! -d "/Users/$1/Documents/opendicom" ]
then
    mkdir -m 775 -p /Users/$1/Documents/opendicom
fi
#spool
if [ ! -d "/Volumes/IN/$3" ]
then
    mkdir -m 775 -p /Volumes/IN/$3/{ARRIVED,CLASSIFIED,FAILURE,ORIGINALS,MISMATCH_ALTERNATES,MISMATCH_SOURCE,MISMATCH_CDAMWL,MISMATCH_PACS}
fi


#launchAgents

coercedicom='/Users/'"$1"'/Library/LaunchAgents/coercedicom.'"$3"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                               >  $coercedicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                >> $coercedicom
echo '<plist version="1.0">'                                                                >> $coercedicom
echo '<dict>'                                                                               >> $coercedicom
echo '    <key>Label</key>'                                                                 >> $coercedicom
echo '    <string>coercedicom.'"$3"'</string>'                                              >> $coercedicom
echo '    <key>ProgramArguments</key>'                                                      >> $coercedicom
echo '    <array>'                                                                          >> $coercedicom
echo '        <string>/usr/local/bin/coercedicom</string>'                                  >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/CLASSIFIED</string>'                               >> $coercedicom
echo '        <string>/Volumes/IN/'"$2"'</string>'                                          >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/FAILURE</string>'                                  >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/ORIGINALS</string>'                                >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/MISMATCH_ALTERNATES</string>'                      >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/MISMATCH_SOURCE</string>'                          >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/MISMATCH_CDAMWL</string>'                          >> $coercedicom
echo '        <string>/Volumes/IN/'"$3"'/MISMATCH_PACS</string>'                            >> $coercedicom
echo '        <string>/Users/Shared/opendicom/coercedicom/'"$3"'/coercedicom.json</string>' >> $coercedicom
echo '        <string>&quot;&quot;</string>'                                                >> $coercedicom
echo '        <string>&quot;&quot;</string>'                                                >> $coercedicom
echo '        <string>90</string>'                                                          >> $coercedicom
echo '        <string>3</string>'                                                           >> $coercedicom
echo '        <string>30</string>'                                                          >> $coercedicom
echo '    </array>'                                                                         >> $coercedicom
echo '    <key>StandardErrorPath</key>'                                                     >> $coercedicom
echo '    <string>/Users/pcs2/Documents/opendicom/coercedicom.'"$3"'.error.log</string>'    >> $coercedicom
echo '    <key>StandardOutPath</key>'                                                       >> $coercedicom
echo '    <string>/Users/pcs2/Documents/opendicom/coercedicom.'"$3"'.log</string>'          >> $coercedicom
echo '    <key>StartInterval</key>'                                                         >> $coercedicom
echo '    <integer>120</integer>'                                                           >> $coercedicom
echo '    <key>Umask</key>'                                                                 >> $coercedicom
echo '    <integer>0</integer>'                                                             >> $coercedicom
echo '</dict>'                                                                              >> $coercedicom
echo '</plist>'                                                                             >> $coercedicom


cleanOriginals='/Users/'"$1"'/Library/LaunchAgents/cleanOriginals.'"$3"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                               >  $cleanOriginals
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                >> $cleanOriginals
echo '<plist version="1.0">'                                                                >> $cleanOriginals
echo '<dict>'                                                                               >> $cleanOriginals
echo '    <key>Label</key>'                                                                 >> $cleanOriginals
echo '    <string>cleanOriginals.'"$3"'</string>'                                           >> $cleanOriginals
echo '    <key>ProgramArguments</key>'                                                      >> $cleanOriginals
echo '    <array>'                                                                          >> $cleanOriginals
echo '        <string>/Users/Shared/opendicom/coercedicom/cleanOriginals.sh</string>'       >> $cleanOriginals
echo '        <string>/Volumes/IN/'"$3"'/ORIGINALS</string>'                                >> $cleanOriginals
echo '        <string>7</string>'                                                           >> $cleanOriginals
echo '        <string>https://serviciosridi.asse.uy/dcm4chee-arc/qido/DCM4CHEE</string>'    >> $cleanOriginals
echo '    </array>'                                                                         >> $cleanOriginals
echo '    <key>StandardErrorPath</key>'                                                     >> $cleanOriginals
echo '    <string>/Users/pcs2/Documents/opendicom/cleanOriginals.'"$3"'.error.log</string>' >> $cleanOriginals
echo '    <key>StandardOutPath</key>'                                                       >> $cleanOriginals
echo '    <string>/Users/pcs2/Documents/opendicom/cleanOriginals.'"$3"'.log</string>'       >> $cleanOriginals
echo '    <key>StartCalendarInterval</key>'                                                 >> $cleanOriginals
echo '    <dict>'                                                                           >> $cleanOriginals
echo '        <key>Hour</key>'                                                              >> $cleanOriginals
echo '        <integer>1</integer>'                                                         >> $cleanOriginals
echo '        <key>Minute</key>'                                                            >> $cleanOriginals
echo '        <integer>0</integer>'                                                         >> $cleanOriginals
echo '    </dict>'                                                                          >> $cleanOriginals
echo '    <key>Umask</key>'                                                                 >> $cleanOriginals
echo '    <integer>0</integer>'                                                             >> $cleanOriginals
echo '</dict>'                                                                              >> $cleanOriginals
echo '</plist>'                                                                             >> $cleanOriginals


#coercedicom directory

if [ ! -d "/Users/Shared/opendicom/coercedicom/$3" ]
then
    mkdir -m 775 -p /Users/Shared/opendicom/coercedicom/$3
fi

ln -s $coercedicom /Users/Shared/opendicom/coercedicom/$3/coercedicom.$3.plist
ln -s $cleanOriginals /Users/Shared/opendicom/coercedicom/$3/cleanOriginals.$3.plist

json="/Users/Shared/opendicom/coercedicom/$3/coercedicom.json"
echo '[{ '                                                                                                  >  $json
echo '"regex":".*", '                                                                                       >> $json
echo '"removeFromDataset":[ "00000001_00101010-AS" ], '                                                     >> $json
echo '"coerceDataset":{ "00000001_00080080-LO":[ "'"$3"'" ]}, '                                             >> $json
echo '"supplementToDataset":{ "00000001_00081060-PN":[ "'"$3"'" ]}, '                                       >> $json
echo '"removeFromEUIDprefixedDataset":{ "2.16.858.2":[ "00000001_00081060-PN", "00000001_00081030-LO" ]}, ' >> $json
echo '"branch":"'"$3"'", '                                                                                  >> $json
echo '"pacsAET":"'"$2"'" '                                                                                  >> $json
echo '}]'                                                                                                   >> $json

start='/Users/Shared/opendicom/coercedicom/'"$3"'/start.sh'
echo '#!/bin/sh'                                 >  $start
echo 'launchctl load -w '"$coercedicom"          >> $start
echo 'launchctl load -w '"$cleanOriginals"       >> $start
echo 'launchctl list | grep "coercedicom.$3"'    >> $start
echo 'launchctl list | grep "cleanOriginals.$3"' >> $start

stop='/Users/Shared/opendicom/coercedicom/'"$3"'/stop.sh'
echo '#!/bin/sh'                                 >  $stop
echo 'launchctl unload -w '"$coercedicom"        >> $stop
echo 'launchctl unload -w '"$cleanOriginals"     >> $stop
echo 'launchctl list | grep "coercedicom.$3"'    >> $stop
echo 'launchctl list | grep "cleanOriginals.$3"' >> $stop



fi
