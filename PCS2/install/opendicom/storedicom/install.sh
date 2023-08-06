#!/bin/bash
# opendicom/storedicom/install.sh'

admin=$1
org=$2
stow=$3
# "https://serviciosridi.asse.uy/dcm4chee-arc/stow"
qido=$4
# "https://serviciosridi.asse.uy/dcm4chee-arc/qido"


storedicom="/Users/$admin/Library/LaunchAgents/storedicom.$org.plist"
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $storedicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $storedicom
echo '<plist version="1.0">'                                                                                  >> $storedicom
echo '<dict>'                                                                                                 >> $storedicom
echo '    <key>Label</key>'                                                                                   >> $storedicom
echo '    <string>storedicom.'"$org"'</string>'                                                               >> $storedicom
echo '    <key>ProgramArguments</key>'                                                                        >> $storedicom
echo '    <array>'                                                                                            >> $storedicom
echo '        <string>/usr/local/Cellar/bash/5.1.16/bin/bash</string>'                                        >> $storedicom
echo '        <string>/Users/Shared/opendicom/storedicom/storedicom.sh</string>'                              >> $storedicom
echo '        <string>/Users/Shared/STORE/DICMhttp11/'"$org"'</string>'                                       >> $storedicom
echo '        <string>'"$stow"'</string>'                                                                     >> $storedicom
echo '        <string>'"$qido"'</string>'                                                                     >> $storedicom
echo '        <string>60</string>'                                                                            >> $storedicom
echo '    </array>'                                                                                           >> $storedicom
echo '    <key>StandardErrorPath</key>'                                                                       >> $storedicom
echo '    <string>/Users/'"$admin"'/Documents/opendicom/storedicom.'"$org"'.error.log</string>'               >> $storedicom
echo '    <key>StandardOutPath</key>'                                                                         >> $storedicom
echo '    <string>/Users/'"$admin"'/Documents/opendicom/storedicom.'"$org"'.log</string>'                     >> $storedicom
echo '    <key>StartInterval</key>'                                                                           >> $storedicom
echo '    <integer>5</integer>'                                                                               >> $storedicom
echo '    <key>Umask</key>'                                                                                   >> $storedicom
echo '    <integer>0</integer>'                                                                               >> $storedicom
echo '</dict>'                                                                                                >> $storedicom
echo '</plist>'                                                                                               >> $storedicom




recycleMismatchInternal='/Users/'"$admin"'/Library/LaunchAgents/recycleMismatchInternal.'"$org"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                              >  $recycleMismatchInternal
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $recycleMismatchInternal
echo '<plist version="1.0">'                                                                                >> $recycleMismatchInternal
echo '<dict>'                                                                                               >> $recycleMismatchInternal
echo '    <key>Label</key>'                                                                                 >> $recycleMismatchInternal
echo '    <string>recycleMismatchInternal.'"$org"'</string>'                                                 >> $recycleMismatchInternal
echo '    <key>ProgramArguments</key>'                                                                      >> $recycleMismatchInternal
echo '    <array>'                                                                                          >> $recycleMismatchInternal
echo '        <string>sh</string>'                                                                          >> $recycleMismatchInternal
echo '        <string>/Users/Shared/opendicom/storedicom/recycleMismatchInternal.sh</string>'                >> $recycleMismatchInternal
echo '        <string>/Users/Shared/STORE/DICMhttp11/'"$org"'/MISMATCH_INTERNAL</string>'                                       >> $recycleMismatchInternal
echo '    </array>'                                                                                         >> $recycleMismatchInternal
echo '    <key>StandardErrorPath</key>'                                                                     >> $recycleMismatchInternal
echo '    <string>/Users/'"$admin"'/Documents/opendicom/recycleMismatchInternal.'"$org"'.error.log</string>' >> $recycleMismatchInternal
echo '    <key>StandardOutPath</key>'                                                                       >> $recycleMismatchInternal
echo '    <string>/Users/'"$admin"'/Documents/opendicom/recycleMismatchInternal.'"$org"'.log</string>'       >> $recycleMismatchInternal
echo '    <key>StartInterval</key>'                                                                         >> $recycleMismatchInternal
echo '    <integer>300</integer>'                                                                           >> $recycleMismatchInternal
echo '    <key>Umask</key>'                                                                                 >> $recycleMismatchInternal
echo '    <integer>0</integer>'                                                                             >> $recycleMismatchInternal
echo '</dict>'                                                                                              >> $recycleMismatchInternal
echo '</plist>'                                                                                             >> $recycleMismatchInternal


mkdir -m 775 -p "/Users/Shared/opendicom/storedicom/$org"
ln -s "$storedicom" "/Users/Shared/opendicom/storedicom/$org/storedicom.$org.plist"
ln -s "$recycleMismatchInternal" "/Users/Shared/opendicom/storedicom/$org/recycleMismatchInternal.$org.plist"

start='/Users/Shared/opendicom/storedicom/'"$org"'/start.sh'
echo '#!/bin/sh'                                               >  $start
echo 'launchctl load -w '"$storedicom"                         >> $start
echo 'launchctl load -w '"$recycleMismatchInternal"             >> $start
echo 'launchctl list | grep "storedicom.'"$org"'"'             >> $start
echo 'launchctl list | grep "recycleMismatchInternal.'"$org"'"' >> $start
chmod -R 775 "$start"

stop='/Users/Shared/opendicom/storedicom/'"$org"'/stop.sh'
echo '#!/bin/sh'                                               >  $stop
echo 'launchctl unload -w '"$storedicom"                       >> $stop
echo 'launchctl unload -w '"$recycleMismatchInternal"           >> $stop
echo 'launchctl list | grep "storedicom.'"$org"'"'             >> $stop
echo 'launchctl list | grep "recycleMismatchInternal.'"$org"'"' >> $stop
chmod -R 775 "$stop"
