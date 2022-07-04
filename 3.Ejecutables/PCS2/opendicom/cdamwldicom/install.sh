#!/bin/bash
# $1= (admin)
# $2= (org)
# $3= (branch)
# $4= (qido for branch OT)

if  [ $1 != '' ] && [ $2 != '' ] && [ $3 != '' ] && [ $4 != '' ]
then

#admin
su $1
#logs
if [ ! -d "/Users/$1/Documents/opendicom" ]
then
    mkdir -m 775 -p /Users/$1/Documents/opendicom
fi
#spool
if [ ! -d "/Users/Shared/opendicom/cdamwldicom/$3" ]
then
    mkdir -m 775 -p /Users/Shared/opendicom/cdamwldicom/$3
fi

cp /Users/Shared/opendicom/cdamwldicom/cda2mwl.xsl /Users/Shared/opendicom/cdamwldicom/$3/cda2mwl.xsl



cdamwldicom='/Users/pcs2/Library/LaunchAgents/cdamwldicom.'"$3"'.'"$2"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                   >  $cdamwldicom
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                 >> $cdamwldicom
echo '<plist version="1.0">'                                                                    >> $cdamwldicom
echo '<dict>'                                                                                   >> $cdamwldicom
echo '    <key>Label</key>'                                                                     >> $cdamwldicom
echo '    <string>cdamwldicom.'"$3"'.'"$2"'</string>'                                           >> $cdamwldicom
echo '    <key>ProgramArguments</key>'                                                          >> $cdamwldicom
echo '    <array>'                                                                              >> $cdamwldicom
echo '        <string>/usr/local/bin/cdamwldicom</string>'                                      >> $cdamwldicom
echo '        <string>/Users/Shared/opendicom/cdamwldicom/'"$3"'/cda2mwl.xsl</string>'          >> $cdamwldicom
echo '        <string>'"$4"'</string>'                                                          >> $cdamwldicom
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$3"'/aet</string>'                         >> $cdamwldicom
echo '        <string>'"$2"'</string>'                                                          >> $cdamwldicom
echo '    </array>'                                                                             >> $cdamwldicom
echo '    <key>StandardErrorPath</key>'                                                         >> $cdamwldicom
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$3"'.'"$2"'.error.log</string>' >> $cdamwldicom
echo '    <key>StandardOutPath</key>'                                                           >> $cdamwldicom
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$3"'.'"$2"'.log</string>'       >> $cdamwldicom
echo '    <key>StartInterval</key>'                                                             >> $cdamwldicom
echo '    <integer>120</integer>'                                                               >> $cdamwldicom
echo '    <key>Umask</key>'                                                                     >> $cdamwldicom
echo '    <integer>0</integer>'                                                                 >> $cdamwldicom
echo '</dict>'                                                                                  >> $cdamwldicom
echo '</plist>'                                                                                 >> $cdamwldicom

ln -s $cdamwldicom /Users/Shared/opendicom/cdamwldicom/$1/cdamwldicom.$3.$2.plist


mvPastWL='/Users/pcs2/Library/LaunchAgents/olditems.'"$3"'.'"$2"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                          >  $mvPastWL
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                 >> $mvPastWL
echo '<plist version="1.0">'                                                           >> $mvPastWL
echo '<dict>'                                                                          >> $mvPastWL
echo '    <key>Label</key>'                                                            >> $mvPastWL
echo '    <string>mvPastWL.'"$3"'.'"$2"'</string>'                                     >> $mvPastWL
echo '    <key>ProgramArguments</key>'                                                 >> $mvPastWL
echo '    <array>'                                                                     >> $mvPastWL
echo '        <string>mv</string>'                                                     >> $mvPastWL
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$3"'/aet/published/$2/*</string>' >> $mvPastWL
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$3"'/aet/`date +%Y%m%d`</string>' >> $mvPastWL
echo '    </array>'                                                                    >> $mvPastWL
echo '    <key>StartCalendarInterval</key>'                                            >> $mvPastWL
echo '    <dict>'                                                                      >> $mvPastWL
echo '        <key>Hour</key>'                                                         >> $mvPastWL
echo '        <integer>23</integer>'                                                   >> $mvPastWL
echo '        <key>Minute</key>'                                                       >> $mvPastWL
echo '        <integer>50</integer>'                                                   >> $mvPastWL
echo '    </dict>'                                                                     >> $mvPastWL
echo '</dict>'                                                                         >> $mvPastWL
echo '</plist>'                                                                        >> $mvPastWL

ln -s $mvPastWL /Users/Shared/opendicom/cdamwldicom/$3/mvPastWL.$3.$2.plist

start='/Users/Shared/opendicom/cdamwldicom/'"$1"'/start.sh'
echo '#!/bin/sh'                                     >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'            >> $start
echo 'launchctl load -w '"$cdamwldicom"              >> $start
echo 'launchctl load -w '"$mvPastWL"                 >> $start
echo 'launchctl list | grep "cdamwldicom.'"$1"'"'    >> $start
echo 'launchctl list | grep "olditems.'"$1"'"'       >> $start

stop='/Users/Shared/opendicom/cdamwldicom/'"$1"'/stop.sh'
echo '#!/bin/sh'                                     >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'            >> $stop
echo 'launchctl unload -w '"$cdamwldicom"            >> $stop
echo 'launchctl unload -w '"$mvPastWL"               >> $stop
echo 'launchctl list | grep "cdamwldicom.'"$1"'"'    >> $stop
echo 'launchctl list | grep "olditems.'"$1"'"'       >> $stop


chmod -R 775        /Users/Shared/opendicom/cdamwldicom/$1

fi
