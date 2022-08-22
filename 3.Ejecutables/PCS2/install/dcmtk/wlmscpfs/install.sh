#!/bin/bash

admin=$1
branch=$2
port=$3
org=$4

mkdir -m 775 -p "/Users/Shared/dcmtk/wlmscpfs/$branch/aet/published/$org"
mkdir -m 775 -p "/Users/$admin/Documents/dcmtk"


plist="/Users/Shared/dcmtk/wlmscpfs/$branch/wlmscpfs.$branch.$org.$port.plist"
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                   >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'   >> $plist
echo '<plist version="1.0">'                                                                                    >> $plist
echo '<dict>'                                                                                                   >> $plist
echo '    <key>Disabled</key>'                                                                                  >> $plist
echo '    <false/>'                                                                                             >> $plist
echo '    <key>EnvironmentVariables</key>'                                                                      >> $plist
echo '    <dict>'                                                                                               >> $plist
echo '        <key>DCMDICTPATH</key>'                                                                           >> $plist
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                                   >> $plist
echo '    </dict>'                                                                                              >> $plist
echo '    <key>KeepAlive</key>'                                                                                 >> $plist
echo '    <true/>'                                                                                              >> $plist
echo '    <key>Label</key>'                                                                                     >> $plist
echo '    <string>wlmscpfs.'"$branch"'.'"$org"'.'"$port"'</string>'                                             >> $plist
echo '    <key>ProgramArguments</key>'                                                                          >> $plist
echo '    <array>'                                                                                              >> $plist
echo '        <string>/usr/local/bin/wlmscpfs</string>'                                                         >> $plist
echo '        <string>-ll</string>'                                                                             >> $plist
echo '        <string>warn</string>'                                                                            >> $plist
echo '        <string>-dfr</string>'                                                                            >> $plist
echo '        <string>-cs1</string>'                                                                            >> $plist
echo '        <string>-nse</string>'                                                                            >> $plist
echo '        <string>+xe</string>'                                                                             >> $plist
echo '        <string>-dfp</string>'                                                                            >> $plist
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/aet/published</string>'                          >> $plist
echo '        <string>'"$port"'</string>'                                                                       >> $plist
echo '    </array>'                                                                                             >> $plist
echo '    <key>StandardErrorPath</key>'                                                                         >> $plist
echo '    <string>/Users/'"$admin"'/Documents/dcmtk/wlmscpfs.'"$branch"'.'"$org"'.'"$port"'.error.log</string>' >> $plist
echo '    <key>StandardOutPath</key>'                                                                           >> $plist
echo '    <string>/Users/'"$admin"'/Documents/dcmtk/wlmscpfs.'"$branch"'.'"$org"'.'"$port"'.log</string>'       >> $plist
echo '</dict>'                                                                                                  >> $plist
echo '</plist>'                                                                                                 >> $plist

export SUDO_ASKPASS=/Users/Shared/pass.sh
sudo -A chmod 644 $plist
sudo -A chown root:wheel $plist
sudo -A mv $plist /Library/LaunchDaemons/
ln -s '/Library/LaunchDaemons/wlmscpfs.'"$branch"'.'"$org"'.'"$port"'.plist' $plist


start='/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/start.sh'
echo '#!/bin/sh'                                                                                         >  $start
echo 'export SUDO_ASKPASS=/Users/Shared/pass.sh'                                                                >> $start
echo 'sudo -A launchctl load -w /Library/LaunchDaemons/wlmscpfs.'"$branch"'.'"$org"'.'"$port"'.plist'    >> $start
echo 'sudo -A launchctl list | grep wlmscpfs.'"$branch"'.'"$org"'.'"$port"                               >> $start
chmod 700 $start

stop='/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/stop.sh'
echo '#!/bin/sh'                                                                                           >  $stop
echo 'export SUDO_ASKPASS=/Users/Shared/pass.sh'                                                                  >> $stop
echo 'sudo -A launchctl unload -w /Library/LaunchDaemons/wlmscpfs.'"$branch"'.'"$org"'.'"$port"'.plist'    >> $stop
echo 'sudo -A launchctl list | grep wlmscpfs.'"$branch"'.'"$org"'.'"$port"                                 >> $stop
chmod 700 $stop
