#!/bin/bash

if  [ $1 != '' ] && [ $2 != '' ] && [ $3 != '' ] && [ $4 != '' ]
then
admin=$1
branch=$2
port=$3
pacs=$4


if [ ! -d "/Users/Shared/dcmtk/wlmscpfs/$branch" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/wlmscpfs/$branch
fi

if [ ! -d "/Users/Shared/dcmtk/wlmscpfs/$branch/aet/published/$pacs" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/wlmscpfs/$branch/aet/published/$pacs
fi

#log
if [ ! -d "/Users/$admin/Documents/dcmtk" ]
then
    mkdir -m 775 -p /Users/$admin/Documents/dcmtk
    chown -R $admin:wheel /Users/$admin/Documents/dcmtk
fi


plist='/Library/LaunchDaemons/wlmscpfs.'"$branch"'.'"$pacs"'.'"$port"'.plist'
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
echo '    <string>wlmscpfs.'"$branch"'.'"$pacs"'.'"$port"'</string>'                                         >> $plist
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
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/aet/published</string>'                       >> $plist
echo '        <string>'"$port"'</string>'                                                                    >> $plist
echo '    </array>'                                                                                          >> $plist
echo '    <key>StandardErrorPath</key>'                                                                      >> $plist
echo '    <string>/Users/Documents/$admin/dcmtk/wlmscpfs.'"$branch"'.'"$pacs"'.'"$port"'.error.log</string>' >> $plist
echo '    <key>StandardOutPath</key>'                                                                        >> $plist
echo '    <string>/Users/Documents/$admin/dcmtk/wlmscpfs.'"$branch"'.'"$pacs"'.'"$port"'.log</string>'       >> $plist
echo '</dict>'                                                                                               >> $plist
echo '</plist>'                                                                                              >> $plist

ln -s $plist /Users/Shared/dcmtk/wlmscpfs/$branch/wlmscpfs.$branch.$pacs.$port.plist

start='/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/start.sh'
echo '#!/bin/sh'                                                                >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                                       >> $start
echo 'sudo -A launchctl load -w '"$plist"                                       >> $start
echo 'sudo -A launchctl list | grep "wlmscpfs.'"$branch"'.'"$pacs"'.'"$port"'"' >> $start

stop='/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/stop.sh'
echo '#!/bin/sh'                                                                >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                                       >> $stop
echo 'sudo -A launchctl unload -w '"$plist"                                     >> $stop
echo 'sudo -A launchctl list | grep "wlmscpfs.'"$branch"'.'"$pacs"'.'"$port"'"' >> $stop


chown -R $admin:wheel /Users/Shared/dcmtk/wlmscpfs/$branch
chmod -R 775 /Users/Shared/dcmtk/wlmscpfs/$branch

fi
