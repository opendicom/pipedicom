#!/bin/bash

# opendicom/cdamwldicom/install.sh
admin=$1
org=$2
branch=$3
qido=$4

mkdir -m 775 -p "/Users/Shared/opendicom/cdamwldicom/$branch"


cdamwldicom='/Users/pcs2/Library/LaunchAgents/cdamwldicom.'"$branch"'.'"$org"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $cdamwldicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $cdamwldicom
echo '<plist version="1.0">'                                                                                  >> $cdamwldicom
echo '<dict>'                                                                                                 >> $cdamwldicom
echo '    <key>Label</key>'                                                                                   >> $cdamwldicom
echo '    <string>cdamwldicom.'"$branch"'.'"$org"'</string>'                                                  >> $cdamwldicom
echo '    <key>ProgramArguments</key>'                                                                        >> $cdamwldicom
echo '    <array>'                                                                                            >> $cdamwldicom
echo '        <string>/usr/local/bin/cdamwldicom</string>'                                                    >> $cdamwldicom
echo '        <string>/Users/Shared/opendicom/cdamwldicom/cda2mwl.xsl</string>'                               >> $cdamwldicom
echo '        <string>'"$4"'</string>'                                                                        >> $cdamwldicom
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/aet</string>'                                  >> $cdamwldicom
echo '        <string>'"$org"'</string>'                                                                      >> $cdamwldicom
echo '    </array>'                                                                                           >> $cdamwldicom
echo '    <key>StandardErrorPath</key>'                                                                       >> $cdamwldicom
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$branch"'.'"$org"'.error.log</string>'        >> $cdamwldicom
echo '    <key>StandardOutPath</key>'                                                                         >> $cdamwldicom
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$branch"'.'"$org"'.log</string>'              >> $cdamwldicom
echo '    <key>StartInterval</key>'                                                                           >> $cdamwldicom
echo '    <integer>120</integer>'                                                                             >> $cdamwldicom
echo '    <key>Umask</key>'                                                                                   >> $cdamwldicom
echo '    <integer>0</integer>'                                                                               >> $cdamwldicom
echo '</dict>'                                                                                                >> $cdamwldicom
echo '</plist>'                                                                                               >> $cdamwldicom

ln -s "$cdamwldicom" "/Users/Shared/opendicom/cdamwldicom/$branch/cdamwldicom.$branch.$org.plist"


cdamwldicomrm='/Users/pcs2/Library/LaunchAgents/cdamwldicom.'"$branch"'.'"$org"'.rm.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                 >  $cdamwldicomrm
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $cdamwldicomrm
echo '<plist version="1.0">'                                                                                  >> $cdamwldicomrm
echo '<dict>'                                                                                                 >> $cdamwldicomrm
echo '    <key>Label</key>'                                                                                   >> $cdamwldicomrm
echo '    <string>cdamwldicom.'"$branch"'.'"$org"'.rm</string>'                                               >> $cdamwldicomrm
echo '    <key>ProgramArguments</key>'                                                                        >> $cdamwldicomrm
echo '    <array>'                                                                                            >> $cdamwldicomrm
echo '        <string>mv</string>'                                                                            >> $cdamwldicomrm
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/aet/published/'"$org"'/*</string>'             >> $cdamwldicomrm
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$branch"'/aet/`date +%Y%m%d`</string>'                   >> $cdamwldicomrm
echo '    </array>'                                                                                           >> $cdamwldicomrm
echo '    <key>StartCalendarInterval</key>'                                                                   >> $cdamwldicomrm
echo '    <dict>'                                                                                             >> $cdamwldicomrm
echo '        <key>Hour</key>'                                                                                >> $cdamwldicomrm
echo '        <integer>23</integer>'                                                                          >> $cdamwldicomrm
echo '        <key>Minute</key>'                                                                              >> $cdamwldicomrm
echo '        <integer>50</integer>'                                                                          >> $cdamwldicomrm
echo '    </dict>'                                                                                            >> $cdamwldicomrm
echo '</dict>'                                                                                                >> $cdamwldicomrm
echo '</plist>'                                                                                               >> $cdamwldicomrm
ln -s "$cdamwldicomrm" "/Users/Shared/opendicom/cdamwldicom/$branch/cdamwldicom.$branch.$org.rm.plist"

start='/Users/Shared/opendicom/cdamwldicom/'"$branch"'/start.sh'
echo '#!/bin/sh'                                                 >  $start
echo 'launchctl load -w '"$cdamwldicom"                          >> $start
echo 'launchctl load -w '"$cdamwldicomrm"                        >> $start
echo 'launchctl list | grep cdamwldicom.'"$branch"'.'"$org"      >> $start
chmod -R 775 "$start"

stop='/Users/Shared/opendicom/cdamwldicom/'"$branch"'/stop.sh'
echo '#!/bin/sh'                                                 >  $stop
echo 'launchctl unload -w '"$cdamwldicom"                        >> $stop
echo 'launchctl unload -w '"$cdamwldicomrm"                      >> $stop
echo 'launchctl list | grep cdamwldicom.'"$branch"'.'"$org"      >> $stop
chmod -R 775 "$stop"
