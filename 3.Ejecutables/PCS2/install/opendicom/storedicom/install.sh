#!/bin/bash
# opendicom/storedicom/install.sh'

admin=$1
org=$2
stow=$3
# "https://serviciosridi.asse.uy/dcm4chee-arc/stow"
qido=$4
# "https://serviciosridi.asse.uy/dcm4chee-arc/qido"

#mkdir -m 775 "/Users/$admin/Documents/opendicom"
mkdir -m 775 -p /Volumes/IN/$org/{SEND,MISMATCH_SERVICE,SENT,LOG}

storedicom="/Users/$admin/Library/LaunchAgents/storedicom.$org.plist"
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $storedicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $storedicom
echo '<plist version="1.0">'                                                                                  >> $storedicom
echo '<dict>'                                                                                                 >> $storedicom
echo '    <key>Label</key>'                                                                                   >> $storedicom
echo '    <string>storedicom.'"$org"'</string>'                                                               >> $storedicom
echo '    <key>ProgramArguments</key>'                                                                        >> $storedicom
echo '    <array>'                                                                                            >> $storedicom
echo '        <string>sh</string>'                                                                            >> $storedicom
echo '        <string>/Users/Shared/opendicom/storedicom/storedicom.sh</string>'                              >> $storedicom
echo '        <string>/Volumes/IN/'"$org"'</string>'                                                          >> $storedicom
echo '        <string>'"$stow"'</string>'                                                                     >> $storedicom
echo '        <string>'"$qido"'</string>'                                                                     >> $storedicom
echo '        <string>120</string>'                                                                           >> $storedicom
echo '    </array>'                                                                                           >> $storedicom
echo '    <key>StandardErrorPath</key>'                                                                       >> $storedicom
echo '    <string>/Users/'"$admin"'/Documents/opendicom/storedicom.'"$org"'.error.log</string>'               >> $storedicom
echo '    <key>StandardOutPath</key>'                                                                         >> $storedicom
echo '    <string>/Users/'"$admin"'/Documents/opendicom/storedicom.'"$org"'.log</string>'                     >> $storedicom
echo '    <key>StartInterval</key>'                                                                           >> $storedicom
echo '    <integer>60</integer>'                                                                              >> $storedicom
echo '    <key>Umask</key>'                                                                                   >> $storedicom
echo '    <integer>0</integer>'                                                                               >> $storedicom
echo '</dict>'                                                                                                >> $storedicom
echo '</plist>'                                                                                               >> $storedicom




recycleMismatchService='/Users/'"$admin"'/Library/LaunchAgents/recycleMismatchService.'"$org"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                              >  $recycleMismatchService
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $recycleMismatchService
echo '<plist version="1.0">'                                                                                >> $recycleMismatchService
echo '<dict>'                                                                                               >> $recycleMismatchService
echo '    <key>Label</key>'                                                                                 >> $recycleMismatchService
echo '    <string>recycleMismatchService.'"$org"'</string>'                                                 >> $recycleMismatchService
echo '    <key>ProgramArguments</key>'                                                                      >> $recycleMismatchService
echo '    <array>'                                                                                          >> $recycleMismatchService
echo '        <string>sh</string>'                                                                          >> $recycleMismatchService
echo '        <string>/Users/Shared/opendicom/storedicom/recycleMismatchService.sh</string>'                >> $recycleMismatchService
echo '        <string>/Volumes/IN/'"$org"'/MISMATCH_SERVICE</string>'                                       >> $recycleMismatchService
echo '    </array>'                                                                                         >> $recycleMismatchService
echo '    <key>StandardErrorPath</key>'                                                                     >> $recycleMismatchService
echo '    <string>/Users/'"$admin"'/Documents/opendicom/recycleMismatchService.'"$org"'.error.log</string>' >> $recycleMismatchService
echo '    <key>StandardOutPath</key>'                                                                       >> $recycleMismatchService
echo '    <string>/Users/'"$admin"'/Documents/opendicom/recycleMismatchService.'"$org"'.log</string>'       >> $recycleMismatchService
echo '    <key>StartInterval</key>'                                                                         >> $recycleMismatchService
echo '    <integer>300</integer>'                                                                           >> $recycleMismatchService
echo '    <key>Umask</key>'                                                                                 >> $recycleMismatchService
echo '    <integer>0</integer>'                                                                             >> $recycleMismatchService
echo '</dict>'                                                                                              >> $recycleMismatchService
echo '</plist>'                                                                                             >> $recycleMismatchService


cleanReferenced='/Users/'"$admin"'/Library/LaunchAgents/cleanReferenced.'"$org"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $cleanReferenced
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $cleanReferenced
echo '<plist version="1.0">'                                                                                  >> $cleanReferenced
echo '<dict>'                                                                                                 >> $cleanReferenced
echo '    <key>Label</key>'                                                                                   >> $cleanReferenced
echo '    <string>cleanReferenced.'"$org"'</string>'                                                          >> $cleanReferenced
echo '    <key>ProgramArguments</key>'                                                                        >> $cleanReferenced
echo '    <array>'                                                                                            >> $cleanReferenced
echo '        <string>sh</string>'                                                                            >> $cleanReferenced
echo '        <string>/Users/Shared/opendicom/storedicom/cleanReferenced.sh</string>'                         >> $cleanReferenced
echo '        <string>/Volumes/IN/'"$org"'/LOG</string>'                                                      >> $cleanReferenced
echo '    </array>'                                                                                           >> $cleanReferenced
echo '    <key>StandardErrorPath</key>'                                                                       >> $cleanReferenced
echo '    <string>/Users/'"$admin"'/Documents/opendicom/storedicom.'"$org"'.error.log</string>'               >> $cleanReferenced
echo '    <key>StandardOutPath</key>'                                                                         >> $cleanReferenced
echo '    <string>/Users/'"$admin"'/Documents/opendicom/storedicom.'"$org"'.log</string>'                     >> $cleanReferenced
echo '    <key>StartCalendarInterval</key>'                                                                   >> $cleanReferenced
echo '    <dict>'                                                                                             >> $cleanReferenced
echo '        <key>Hour</key>'                                                                                >> $cleanReferenced
echo '        <integer>2</integer>'                                                                           >> $cleanReferenced
echo '        <key>Minute</key>'                                                                              >> $cleanReferenced
echo '        <integer>0</integer>'                                                                           >> $cleanReferenced
echo '    </dict>'                                                                                            >> $cleanReferenced
echo '    <key>Umask</key>'                                                                                   >> $cleanReferenced
echo '    <integer>0</integer>'                                                                               >> $cleanReferenced
echo '</dict>'                                                                                                >> $cleanReferenced
echo '</plist>'                                                                                               >> $cleanReferenced

mkdir -m 775 -p "/Users/Shared/opendicom/storedicom/$org"
ln -s "$storedicom" "/Users/Shared/opendicom/storedicom/$org/storedicom.$org.plist"
ln -s "$recycleMismatchService" "/Users/Shared/opendicom/storedicom/$org/recycleMismatchService.$org.plist"
ln -s "$cleanReferenced" "/Users/Shared/opendicom/storedicom/$org/cleanReferenced.$org.plist"

start='/Users/Shared/opendicom/storedicom/'"$org"'/start.sh'
echo '#!/bin/sh'                                               >  $start
echo 'launchctl load -w '"$storedicom"                         >> $start
echo 'launchctl load -w '"$recycleMismatchService"             >> $start
echo 'launchctl load -w '"$cleanReferenced"                    >> $start
echo 'launchctl list | grep "storedicom.'"$org"'"'             >> $start
echo 'launchctl list | grep "recycleMismatchService.'"$org"'"' >> $start
echo 'launchctl list | grep "cleanReferenced.'"$org"'"'        >> $start
chmod -R 775 "$start"

stop='/Users/Shared/opendicom/storedicom/'"$org"'/stop.sh'
echo '#!/bin/sh'                                               >  $stop
echo 'launchctl unload -w '"$storedicom"                       >> $stop
echo 'launchctl unload -w '"$recycleMismatchService"           >> $stop
echo 'launchctl unload -w '"$cleanReferenced"                  >> $stop
echo 'launchctl list | grep "storedicom.'"$org"'"'             >> $stop
echo 'launchctl list | grep "recycleMismatchService.'"$org"'"' >> $stop
echo 'launchctl list | grep "cleanReferenced.'"$org"'"'        >> $stop
chmod -R 775 "$stop"
