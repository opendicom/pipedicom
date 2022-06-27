#!/bin/bash
if [ "$#" -ne 4 ]; then
   echo 'opendicom/coercedicom/install.sh'
   echo '$1= (pcs aet)'
   echo '$2= (pacs aet)'
   echo '$3= (admin user name)'
else

if [ ! -d "/Users/Shared/opendicom/coercedicom/$1" ]
then
    if [ ! -d "/Users/Shared/opendicom/coercedicom" ]
    then
        mkdir -m 775 /Users/Shared/opendicom/coercedicom
        chown $3:wheel /Users/Shared/opendicom/coercedicom
    fi
    mkdir -m 775 /Users/Shared/opendicom/coercedicom/$1
fi

json="/Users/Shared/opendicom/coercedicom/$1/coercedicom.json"
echo '[{ '                                                              >  $json
echo '"regex":"^.*", '                                                  >> $json
echo '"removeFromDataset":[ "00000001_00101010-AS" ], '                 >> $json
echo '"coerceDataset":{ "00000001_00080080-LO" :[ "'"$1"'" ]}, '        >> $json
echo '"removeFromDataset":[ "00000001_00081060-PN" ]'                   >> $json
echo '}]'                                                               >> $json

#log
if [ ! -d "/Users/pcs2/Documents/opendicom" ]
then
    mkdir -m 775 -p /Users/$3/Documents/opendicom
    chown -R $3:wheel /Users/$3/Documents/opendicom
fi

plist='/Users/'"$3"'/Library/LaunchAgents/coercedicom.'"$1"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                               >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                      >> $plist
echo '<plist version="1.0">'                                                                >> $plist
echo '<dict>'                                                                               >> $plist
echo '    <key>Label</key>'                                                                 >> $plist
echo '    <string>coercedicom.'"$1"'.plist</string>'                                        >> $plist
echo '    <key>ProgramArguments</key>'                                                      >> $plist
echo '    <array>'                                                                          >> $plist
echo '        <string>/usr/local/bin/coercedicom</string>'                                  >> $plist
echo '        <string>/Volumes/IN/'"$1"'/CLASSIFIED</string>'                               >> $plist
echo '        <string>/Volumes/IN/'"$2"'/SEND</string>'                                     >> $plist
echo '        <string>/Volumes/IN/'"$1"'/FAILURE</string>'                                  >> $plist
echo '        <string>/Volumes/IN/'"$1"'/ORIGINALS</string>'                                >> $plist
echo '        <string>/Volumes/IN/'"$1"'/MISMATCH_SOURCE</string>'                          >> $plist
echo '        <string>/Volumes/IN/'"$1"'/MISMATCH_CDAMWL</string>'                          >> $plist
echo '        <string>/Volumes/IN/'"$1"'/MISMATCH_PACS</string>'                            >> $plist
echo '        <string>/Users/Shared/opendicom/coercedicom/'"$1"'/coercedicom.json</string>' >> $plist
echo '        <string>&quot;&quot;</string>'                                                >> $plist
echo '        <string>&quot;&quot;</string>'                                                >> $plist
echo '        <string>90</string>'                                                          >> $plist
echo '        <string>3</string>'                                                           >> $plist
echo '        <string>30</string>'                                                          >> $plist
echo '    </array>'                                                                         >> $plist
echo '    <key>StandardErrorPath</key>'                                                     >> $plist
echo '    <string>/Users/pcs2/Documents/opendicom/coercedicom.'"$1"'.error.log</string>'    >> $plist
echo '    <key>StandardOutPath</key>'                                                       >> $plist
echo '    <string>/Users/pcs2/Documents/opendicom/coercedicom.'"$1"'.log</string>'          >> $plist
echo '    <key>StartInterval</key>'                                                         >> $plist
echo '    <integer>120</integer>'                                                            >> $plist
echo '    <key>Umask</key>'                                                                 >> $plist
echo '    <integer>0</integer>'                                                             >> $plist
echo '</dict>'                                                                              >> $plist
echo '</plist>'                                                                             >> $plist

ln -s $plist /Users/Shared/opendicom/coercedicom/$1/coercedicom.$1.plist

start='/Users/Shared/opendicom/coercedicom/'"$1"'/start.sh'
echo '#!/bin/sh'                           >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'  >> $start
echo 'launchctl load -w '"$plist"          >> $start
echo 'launchctl list | grep "coercedicom"' >> $start

stop='/Users/Shared/opendicom/coercedicom/'"$1"'/stop.sh'
echo '#!/bin/sh'                           >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'  >> $stop
echo 'launchctl unload -w '"$plist"        >> $stop
echo 'launchctl list | grep "coercedicom"' >> $stop


chown -R $3:wheel   /Users/Shared/opendicom/coercedicom/$1
chmod -R 775        /Users/Shared/opendicom/coercedicom/$1

fi
