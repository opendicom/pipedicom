#!/bin/bash
# $1= (org)
# $2= (aet)
# $3= (url)

if  [ $1 != '' ] && [ $2 != '' ] && [ $3 != '' ]
then

if [ ! -d "/Users/Shared/opendicom/cdamwldicom/$1" ]
then
    mkdir -m 775 -p /Users/Shared/opendicom/cdamwldicom/$1
fi

cp /Users/Shared/opendicom/cdamwldicom/cda2mwl.xsl /Users/Shared/opendicom/cdamwldicom/$1/cda2mwl.xsl

#log
if [ ! -d "/Users/pcs2/Documents/opendicom" ]
then
    mkdir -m 775 -p /Users/pcs2/Documents/opendicom
    chown -R pcs2:wheel /Users/pcs2/Documents/opendicom
fi
ln -s /Users/pcs2/Documents/opendicom /Users/Shared/opendicom/cdamwldicom/$1/log


plist='/Users/pcs2/Library/LaunchAgents/cdamwldicom.'"$1"'.'"$2"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                             >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                    >> $plist
echo '<plist version="1.0">'                                                              >> $plist
echo '<dict>'                                                                             >> $plist
echo '    <key>Label</key>'                                                               >> $plist
echo '    <string>cdamwldicom.'"$1"'.'"$2"'.plist</string>'                               >> $plist
echo '    <key>ProgramArguments</key>'                                                    >> $plist
echo '    <array>'                                                                        >> $plist
echo '        <string>/usr/local/bin/cdamwldicom</string>'                                >> $plist
echo '        <string>/Users/Shared/opendicom/cdamwldicom/'"$1"'/cda2mwl.xsl</string>'    >> $plist
echo '        <string>'"$3"'</string>'                                                    >> $plist
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$1"'/aet</string>'                   >> $plist
echo '        <string>'"$2"'</string>'                                                    >> $plist
echo '    </array>'                                                                       >> $plist
echo '    <key>StandardErrorPath</key>'                                                   >> $plist
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$1"'.'"$2"'.error.log</string>'                                                                                             >> $plist
echo '    <key>StandardOutPath</key>'                                                     >> $plist
echo '    <string>/Users/pcs2/Documents/opendicom/cdamwldicom.'"$1"'.'"$2"'.log</string>' >> $plist
echo '    <key>StartInterval</key>'                                                       >> $plist
echo '    <integer>120</integer>'                                                         >> $plist
echo '    <key>Umask</key>'                                                               >> $plist
echo '    <integer>0</integer>'                                                           >> $plist
echo '</dict>'                                                                            >> $plist
echo '</plist>'                                                                           >> $plist

ln -s $plist /Users/Shared/opendicom/cdamwldicom/$1/cdamwldicom.$1.$2.plist


plistold='/Users/pcs2/Library/LaunchAgents/olditems.'"$1"'.'"$2"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                          >  $plistold
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                 >> $plistold
echo '<plist version="1.0">'                                                           >> $plistold
echo '<dict>'                                                                          >> $plistold
echo '    <key>Label</key>'                                                            >> $plistold
echo '    <string>olditems.'"$1"'.'"$2"'.plist</string>'                               >> $plistold
echo '    <key>ProgramArguments</key>'                                                 >> $plistold
echo '    <array>'                                                                     >> $plistold
echo '        <string>mv</string>'                                                     >> $plistold
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$1"'/aet/published/DCM4CHEE/*</string>'                                                                                             >> $plistold
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$1"'/aet/`date +%Y%m%d`</string>' >> $plistold
echo '    </array>'                                                                    >> $plistold
echo '    <key>StartCalendarInterval</key>'                                            >> $plistold
echo '    <dict>'                                                                      >> $plistold
echo '        <key>Hour</key>'                                                         >> $plistold
echo '        <integer>23</integer>'                                                   >> $plistold
echo '        <key>Minute</key>'                                                       >> $plistold
echo '        <integer>50</integer>'                                                   >> $plistold
echo '    </dict>'                                                                     >> $plistold
echo '</dict>'                                                                         >> $plistold
echo '</plist>'                                                                        >> $plistold

ln -s $plistold /Users/Shared/opendicom/cdamwldicom/$1/olditems.$1.$2.plist

start='/Users/Shared/opendicom/cdamwldicom/'"$1"'/start.sh'
echo '#!/bin/sh'                                     >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'            >> $start
echo 'launchctl load -w '"$plist"                    >> $start
echo 'launchctl load -w '"$plistold"                 >> $start
echo 'launchctl list | grep "cdamwldicom.'"$1"'"'    >> $start
echo 'launchctl list | grep "olditems.'"$1"'"'       >> $start

stop='/Users/Shared/opendicom/cdamwldicom/'"$1"'/stop.sh'
echo '#!/bin/sh'                                     >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'            >> $stop
echo 'launchctl unload -w '"$plist"                  >> $stop
echo 'launchctl unload -w '"$plistold"               >> $stop
echo 'launchctl list | grep "cdamwldicom.'"$1"'"'    >> $stop
echo 'launchctl list | grep "olditems.'"$1"'"'       >> $stop


chown -R pcs2:wheel /Users/Shared/opendicom/cdamwldicom/$1
chmod -R 775        /Users/Shared/opendicom/cdamwldicom/$1

fi
