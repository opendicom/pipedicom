#!/bin/bash

ADMIN=$1
BRANCH=$2
PORT=$3
ORG=$4


if [ ! -d "/Users/Shared/dcmtk/wlmscpfs/$BRANCH" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/wlmscpfs/$BRANCH
fi

if [ ! -d "/Users/Shared/dcmtk/wlmscpfs/$BRANCH/aet/published/$ORG" ]
then
    mkdir -m 775 -p "/Users/Shared/dcmtk/wlmscpfs/$BRANCH/aet/published/$ORG"
fi

#log
if [ ! -d "/Users/$ADMIN/Documents/dcmtk" ]
then
    mkdir -m 775 -p "/Users/$ADMIN/Documents/dcmtk"
    chown -R "$ADMIN":wheel "/Users/$ADMIN/Documents/dcmtk"
fi


plist='/Library/LaunchDaemons/wlmscpfs.'"$BRANCH"'.'"$ORG"'.'"$PORT"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                 >> $plist
echo '<plist version="1.0">'                                                                                 >> $plist
echo '<dict>'                                                                                                >> $plist
echo '    <key>Disabled</key>'                                                                               >> $plist
echo '    <false/>'                                                                                          >> $plist
echo '    <key>EnvironmentVariables</key>'                                                                   >> $plist
echo '    <dict>'                                                                                            >> $plist
echo '        <key>DCMDICTPATH</key>'                                                                        >> $plist
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                                >> $plist
echo '    </dict>'                                                                                           >> $plist
echo '    <key>KeepAlive</key>'                                                                              >> $plist
echo '    <true/>'                                                                                           >> $plist
echo '    <key>Label</key>'                                                                                  >> $plist
echo '    <string>wlmscpfs.'"$BRANCH"'.'"$ORG"'.'"$PORT"'</string>'                                         >> $plist
echo '    <key>ProgramArguments</key>'                                                                       >> $plist
echo '    <array>'                                                                                           >> $plist
echo '        <string>/usr/local/bin/wlmscpfs</string>'                                                      >> $plist
echo '        <string>-ll</string>'                                                                          >> $plist
echo '        <string>warn</string>'                                                                         >> $plist
echo '        <string>-dfr</string>'                                                                         >> $plist
echo '        <string>-cs1</string>'                                                                         >> $plist
echo '        <string>-nse</string>'                                                                         >> $plist
echo '        <string>+xe</string>'                                                                          >> $plist
echo '        <string>-dfp</string>'                                                                         >> $plist
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$BRANCH"'/aet/published</string>'                       >> $plist
echo '        <string>'"$PORT"'</string>'                                                                    >> $plist
echo '    </array>'                                                                                          >> $plist
echo '    <key>StandardErrorPath</key>'                                                                      >> $plist
echo '    <string>/Users/Documents/'"$ADMIN"'/dcmtk/wlmscpfs.'"$BRANCH"'.'"$ORG"'.'"$PORT"'.error.log</string>' >> $plist
echo '    <key>StandardOutPath</key>'                                                                        >> $plist
echo '    <string>/Users/Documents/'"$ADMIN"'/dcmtk/wlmscpfs.'"$BRANCH"'.'"$ORG"'.'"$PORT"'.log</string>'       >> $plist
echo '</dict>'                                                                                               >> $plist
echo '</plist>'                                                                                              >> $plist

ln -s "$plist" "/Users/Shared/dcmtk/wlmscpfs/$BRANCH/wlmscpfs.$BRANCH.$ORG.$PORT.plist"

start='/Users/Shared/dcmtk/wlmscpfs/'"$BRANCH"'/start.sh'
echo '#!/bin/sh'                                                                >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                                       >> $start
echo 'sudo -A launchctl load -w '"$plist"                                       >> $start
echo 'sudo -A launchctl list | grep "wlmscpfs.'"$BRANCH"'.'"$ORG"'.'"$PORT"'"'  >> $start

stop='/Users/Shared/dcmtk/wlmscpfs/'"$BRANCH"'/stop.sh'
echo '#!/bin/sh'                                                                >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                                       >> $stop
echo 'sudo -A launchctl unload -w '"$plist"                                     >> $stop
echo 'sudo -A launchctl list | grep "wlmscpfs.'"$BRANCH"'.'"$ORG"'.'"$PORT"'"'  >> $stop


chown -R "$ADMIN":wheel "/Users/Shared/dcmtk/wlmscpfs/$BRANCH"
chmod -R 775 "/Users/Shared/dcmtk/wlmscpfs/$BRANCH"
