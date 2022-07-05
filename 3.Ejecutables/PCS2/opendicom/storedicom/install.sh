#!/bin/bash

# opendicom/storedicom/install.sh'
ADMIN=$1
ORG=$2
STOW=$3
# "https://serviciosridi.asse.uy/dcm4chee-arc/stow"
QIDO=$4
# "https://serviciosridi.asse.uy/dcm4chee-arc/qido"


#logs
if [ ! -d "/Users/$ADMIN/Documents/opendicom" ]
then
    mkdir -m 775 "/Users/$ADMIN/Documents/opendicom"
fi
#spool
if [ ! -d "/Volumes/IN/$ORG" ]
then
    mkdir -m 775 -p "/Volumes/IN/$ORG/{SEND,MISMATCH_SERVICE,SENT,LOG}"
fi


#launchAgents

storedicom='/Users/'"$ADMIN"'/Library/LaunchAgents/storedicom.'"$ORG"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                             >  $storedicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $storedicom
echo '<plist version="1.0">'                                                              >> $storedicom
echo '<dict>'                                                                             >> $storedicom
echo '    <key>Label</key>'                                                               >> $storedicom
echo '    <string>storedicom.'"$ORG"'</string>'                                           >> $storedicom
echo '    <key>ProgramArguments</key>'                                                    >> $storedicom
echo '    <array>'                                                                        >> $storedicom
echo '        <string>sh</string>'                                                        >> $storedicom
echo '        <string>/Users/Shared/opendicom/storedicom/storedicom.sh</string>'          >> $storedicom
echo '        <string>/Volumes/IN/'"$ORG"'</string>'                                      >> $storedicom
echo '        <string>'"$STOW"'</string>'                                                 >> $storedicom
echo '        <string>'"$QIDO"'</string>'                                                 >> $storedicom
echo '        <string>120</string>'                                                       >> $storedicom
echo '    </array>'                                                                       >> $storedicom
echo '    <key>StandardErrorPath</key>'                                                   >> $storedicom
echo '    <string>/Users/pcs2/Documents/opendicom/storedicom.'"$ORG"'.error.log</string>' >> $storedicom
echo '    <key>StandardOutPath</key>'                                                     >> $storedicom
echo '    <string>/Users/pcs2/Documents/opendicom/storedicom.'"$ORG"'.log</string>'       >> $storedicom
echo '    <key>StartInterval</key>'                                                       >> $storedicom
echo '    <integer>60</integer>'                                                          >> $storedicom
echo '    <key>Umask</key>'                                                               >> $storedicom
echo '    <integer>0</integer>'                                                           >> $storedicom
echo '</dict>'                                                                            >> $storedicom
echo '</plist>'                                                                           >> $storedicom




recycleMismatchService='/Users/pcs2/Library/LaunchAgents/recycleMismatchService.'"$ORG"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                         >  $recycleMismatchService
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $recycleMismatchService
echo '<plist version="1.0">'                                                                          >> $recycleMismatchService
echo '<dict>'                                                                                         >> $recycleMismatchService
echo '    <key>Label</key>'                                                                           >> $recycleMismatchService
echo '    <string>recycleMismatchService.'"$ORG"'</string>'                                           >> $recycleMismatchService
echo '    <key>ProgramArguments</key>'                                                                >> $recycleMismatchService
echo '    <array>'                                                                                    >> $recycleMismatchService
echo '        <string>sh</string>'                                                                    >> $recycleMismatchService
echo '        <string>/Users/Shared/opendicom/storedicom/recycleMismatchService.sh</string>'          >> $recycleMismatchService
echo '        <string>/Volumes/IN/'"$ORG"'/MISMATCH_SERVICE</string>'                                 >> $recycleMismatchService
echo '    </array>'                                                                                   >> $recycleMismatchService
echo '    <key>StandardErrorPath</key>'                                                               >> $recycleMismatchService
echo '    <string>/Users/pcs2/Documents/opendicom/recycleMismatchService.'"$ORG"'.error.log</string>' >> $recycleMismatchService
echo '    <key>StandardOutPath</key>'                                                                 >> $recycleMismatchService
echo '    <string>/Users/pcs2/Documents/opendicom/recycleMismatchService.'"$ORG"'.log</string>'       >> $recycleMismatchService
echo '    <key>StartInterval</key>'                                                                   >> $recycleMismatchService
echo '    <integer>1800</integer>'                                                                    >> $recycleMismatchService
echo '    <key>Umask</key>'                                                                           >> $recycleMismatchService
echo '    <integer>0</integer>'                                                                       >> $recycleMismatchService
echo '</dict>'                                                                                        >> $recycleMismatchService
echo '</plist>'                                                                                       >> $recycleMismatchService


cleanReferenced='/Users/pcs2/Library/LaunchAgents/cleanReferenced.'"$ORG"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                            >  $cleanReferenced
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $cleanReferenced
echo '<plist version="1.0">'                                                              >> $cleanReferenced
echo '<dict>'                                                                             >> $cleanReferenced
echo '    <key>Label</key>'                                                               >> $cleanReferenced
echo '    <string>cleanReferenced.'"$ORG"'</string>'                                      >> $cleanReferenced
echo '    <key>ProgramArguments</key>'                                                    >> $cleanReferenced
echo '    <array>'                                                                        >> $cleanReferenced
echo '        <string>sh</string>'                                                        >> $cleanReferenced
echo '        <string>/Users/Shared/opendicom/storedicom/cleanReferenced.sh</string>'     >> $cleanReferenced
echo '        <string>/Volumes/IN/'"$ORG"'/LOG</string>'                                  >> $cleanReferenced
echo '    </array>'                                                                       >> $cleanReferenced
echo '    <key>StandardErrorPath</key>'                                                   >> $cleanReferenced
echo '    <string>/Users/pcs2/Documents/opendicom/storedicom.'"$ORG"'.error.log</string>' >> $cleanReferenced
echo '    <key>StandardOutPath</key>'                                                     >> $cleanReferenced
echo '    <string>/Users/pcs2/Documents/opendicom/storedicom.'"$ORG"'.log</string>'       >> $cleanReferenced
echo '    <key>StartCalendarInterval</key>'                                               >> $cleanReferenced
echo '    <dict>'                                                                         >> $cleanReferenced
echo '        <key>Hour</key>'                                                            >> $cleanReferenced
echo '        <integer>2</integer>'                                                       >> $cleanReferenced
echo '        <key>Minute</key>'                                                          >> $cleanReferenced
echo '        <integer>0</integer>'                                                       >> $cleanReferenced
echo '    </dict>'                                                                        >> $cleanReferenced
echo '    <key>Umask</key>'                                                               >> $cleanReferenced
echo '    <integer>0</integer>'                                                           >> $cleanReferenced
echo '</dict>'                                                                            >> $cleanReferenced
echo '</plist>'                                                                           >> $cleanReferenced



#storedicom directory

if [ ! -d "/Users/Shared/opendicom/storedicom/$ORG" ]
then
    mkdir -m 775 -p "/Users/Shared/opendicom/storedicom/$ORG"
fi

ln -s "$storedicom" "/Users/Shared/opendicom/storedicom/$ORG/storedicom.$ORG.plist"
ln -s "$recycleMismatchService" "/Users/Shared/opendicom/storedicom/$ORG/recycleMismatchService.$ORG.plist"
ln -s "$cleanReferenced" "/Users/Shared/opendicom/storedicom/$ORG/cleanReferenced.$ORG.plist"

start='/Users/Shared/opendicom/storedicom/'"$ORG"'/start.sh'
echo '#!/bin/sh'                                               >  $start
echo 'launchctl load -w '"$storedicom"                         >> $start
echo 'launchctl load -w '"$recycleMismatchService"             >> $start
echo 'launchctl load -w '"$cleanReferenced"                    >> $start
echo 'launchctl list | grep "storedicom.'"$ORG"'"'             >> $start
echo 'launchctl list | grep "recycleMismatchService.'"$ORG"'"' >> $start
echo 'launchctl list | grep "cleanReferenced.'"$ORG"'"'        >> $start

stop='/Users/Shared/opendicom/storedicom/'"$ORG"'/stop.sh'
echo '#!/bin/sh'                                               >  $stop
echo 'launchctl unload -w '"$storedicom"                       >> $stop
echo 'launchctl unload -w '"$recycleMismatchService"           >> $stop
echo 'launchctl unload -w '"$cleanReferenced"                  >> $stop
echo 'launchctl list | grep "storedicom.'"$ORG"'"'             >> $stop
echo 'launchctl list | grep "recycleMismatchService.'"$ORG"'"' >> $stop
echo 'launchctl list | grep "cleanReferenced.'"$ORG"'"'        >> $stop

chmod -R 775 "/Users/Shared/opendicom/storedicom/$ORG"
