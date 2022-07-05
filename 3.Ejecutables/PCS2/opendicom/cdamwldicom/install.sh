#!/bin/bash

# opendicom/cdamwldicom/install.sh
ADMIN=$1
ORG=$2
BRANCH=$3
QIDO=$4

#logs
if [ ! -d "/Users/$ADMIN/Documents/opendicom" ]
then
    mkdir -m 775 -p "/Users/$ADMIN/Documents/opendicom"
fi
#spool
if [ ! -d "/Users/Shared/opendicom/cdamwldicom/$BRANCH" ]
then
    mkdir -m 775 -p "/Users/Shared/opendicom/cdamwldicom/$BRANCH"
fi

cp "/Users/Shared/opendicom/cdamwldicom/cda2mwl.xsl" "/Users/Shared/opendicom/cdamwldicom/$BRANCH/cda2mwl.xsl"



cdamwldicom='/Users/pcs2/Library/LaunchAgents/cdamwldicom.'"$BRANCH"'.'"$ORG"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                         >  $cdamwldicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $cdamwldicom
echo '<plist version="1.0">'                                                                           >> $cdamwldicom
echo '<dict>'                                                                                          >> $cdamwldicom
echo '    <key>Label</key>'                                                                            >> $cdamwldicom
echo '    <string>cdamwldicom.'"$BRANCH"'.'"$ORG"'</string>'                                           >> $cdamwldicom
echo '    <key>ProgramArguments</key>'                                                                 >> $cdamwldicom
echo '    <array>'                                                                                     >> $cdamwldicom
echo '        <string>/usr/local/bin/cdamwldicom</string>'                                             >> $cdamwldicom
echo '        <string>/Users/Shared/opendicom/cdamwldicom/'"$BRANCH"'/cda2mwl.xsl</string>'            >> $cdamwldicom
echo '        <string>'"$4"'</string>'                                                                 >> $cdamwldicom
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$BRANCH"'/aet</string>'                           >> $cdamwldicom
echo '        <string>'"$ORG"'</string>'                                                               >> $cdamwldicom
echo '    </array>'                                                                                    >> $cdamwldicom
echo '    <key>StandardErrorPath</key>'                                                                >> $cdamwldicom
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$BRANCH"'.'"$ORG"'.error.log</string>' >> $cdamwldicom
echo '    <key>StandardOutPath</key>'                                                                  >> $cdamwldicom
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$BRANCH"'.'"$ORG"'.log</string>'       >> $cdamwldicom
echo '    <key>StartInterval</key>'                                                                    >> $cdamwldicom
echo '    <integer>120</integer>'                                                                      >> $cdamwldicom
echo '    <key>Umask</key>'                                                                            >> $cdamwldicom
echo '    <integer>0</integer>'                                                                        >> $cdamwldicom
echo '</dict>'                                                                                         >> $cdamwldicom
echo '</plist>'                                                                                        >> $cdamwldicom

ln -s "$cdamwldicom" "/Users/Shared/opendicom/cdamwldicom/$BRANCH/cdamwldicom.$BRANCH.$ORG.plist"


mvPastWL='/Users/pcs2/Library/LaunchAgents/mvPastWL.'"$BRANCH"'.'"$ORG"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                     >  $mvPastWL
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'             >> $mvPastWL
echo '<plist version="1.0">'                                                                      >> $mvPastWL
echo '<dict>'                                                                                     >> $mvPastWL
echo '    <key>Label</key>'                                                                       >> $mvPastWL
echo '    <string>mvPastWL.'"$BRANCH"'.'"$ORG"'</string>'                                         >> $mvPastWL
echo '    <key>ProgramArguments</key>'                                                            >> $mvPastWL
echo '    <array>'                                                                                >> $mvPastWL
echo '        <string>mv</string>'                                                                >> $mvPastWL
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$BRANCH"'/aet/published/'"$ORG"'/*</string>' >> $mvPastWL
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$BRANCH"'/aet/`date +%Y%m%d`</string>'       >> $mvPastWL
echo '    </array>'                                                                               >> $mvPastWL
echo '    <key>StartCalendarInterval</key>'                                                       >> $mvPastWL
echo '    <dict>'                                                                                 >> $mvPastWL
echo '        <key>Hour</key>'                                                                    >> $mvPastWL
echo '        <integer>23</integer>'                                                              >> $mvPastWL
echo '        <key>Minute</key>'                                                                  >> $mvPastWL
echo '        <integer>50</integer>'                                                              >> $mvPastWL
echo '    </dict>'                                                                                >> $mvPastWL
echo '</dict>'                                                                                    >> $mvPastWL
echo '</plist>'                                                                                   >> $mvPastWL

ln -s "$mvPastWL" "/Users/Shared/opendicom/cdamwldicom/$BRANCH/mvPastWL.$BRANCH.$ORG.plist"

start='/Users/Shared/opendicom/cdamwldicom/'"$BRANCH"'/start.sh'
echo '#!/bin/sh'                                       >  $start
echo 'launchctl load -w '"$cdamwldicom"                >> $start
echo 'launchctl load -w '"$mvPastWL"                   >> $start
echo 'launchctl list | grep "cdamwldicom.'"$BRANCH"'"' >> $start
echo 'launchctl list | grep "mvPastWL.'"$BRANCH"'"'    >> $start

stop='/Users/Shared/opendicom/cdamwldicom/'"$BRANCH"'/stop.sh'
echo '#!/bin/sh'                                       >  $stop
echo 'launchctl unload -w '"$cdamwldicom"              >> $stop
echo 'launchctl unload -w '"$mvPastWL"                 >> $stop
echo 'launchctl list | grep "cdamwldicom.'"$BRANCH"'"' >> $stop
echo 'launchctl list | grep "mvPastWL.'"$BRANCH"'"'    >> $stop


chmod -R 775        "/Users/Shared/opendicom/cdamwldicom/$BRANCH"
