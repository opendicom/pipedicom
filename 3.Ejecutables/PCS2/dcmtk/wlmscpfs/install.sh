#!/bin/bash
# $1= (org)
# $2= (port)
# $3= (aet)


if  [ $1 != '' ] && [ $2 != '' ] && [ $3 != '' ]
then

if [ ! -d "/Users/Shared/dcmtk/wlmscpfs/$1" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/wlmscpfs/$1
fi

if [ ! -d "/Users/Shared/dcmtk/wlmscpfs/$1/aet/published/$3" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/wlmscpfs/$1/aet/published/$3
fi

#log
if [ ! -d "/Users/pcs2/Documents/dcmtk" ]
then
    mkdir -m 775 -p /Users/pcs2/Documents/dcmtk
    chown -R pcs2:wheel /Users/pcs2/Documents/dcmtk
fi


plist='/Library/LaunchDaemons/wlmscpfs.'"$1"'.'"$3"'.'"$2"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                         >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                >> $plist
echo '<plist version="1.0">'                                                          >> $plist
echo '<dict>'                                                                         >> $plist
echo '    <key>Disabled</key>'                                                        >> $plist
echo '    <false/>'                                                                   >> $plist
echo '    <key>EnvironmentVariables</key>'                                            >> $plist
echo '    <dict>'                                                                     >> $plist
echo '        <key>DCMDICTPATH</key>'                                                 >> $plist
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                         >> $plist
echo '    </dict>'                                                                    >> $plist
echo '    <key>KeepAlive</key>'                                                       >> $plist
echo '    <true/>'                                                                    >> $plist
echo '    <key>Label</key>'                                                           >> $plist
echo '    <string>wlmscpfs.'"$1"'.'"$3"'.'"$2"'.plist</string>'                       >> $plist
echo '    <key>ProgramArguments</key>'                                                >> $plist
echo '    <array>'                                                                    >> $plist
echo '        <string>/usr/local/bin/wlmscpfs</string>'                               >> $plist
echo '        <string>-ll</string>'                                                   >> $plist
echo '        <string>warn</string>'                                                  >> $plist
echo '        <string>-dfr</string>'                                                  >> $plist
echo '        <string>-cs1</string>'                                                  >> $plist
echo '        <string>-nse</string>'                                                  >> $plist
echo '        <string>+xe</string>'                                                   >> $plist
echo '        <string>-dfp</string>'                                                  >> $plist
echo '        <string>/Users/Shared/dcmtk/wlmscpfs/'"$1"'/aet/published</string>'     >> $plist
echo '        <string>'"$2"'</string>'                                                >> $plist
echo '    </array>'                                                                   >> $plist
echo '    <key>StandardErrorPath</key>'                                               >> $plist
echo '    <string>/Users/Documents/pcs2/dcmtk/wlmscpfs.'"$1"'.'"$3"'.'"$2"'.error.log</string>' >> $plist
echo '    <key>StandardOutPath</key>'                                                 >> $plist
echo '    <string>/Users/Documents/pcs2/dcmtk/wlmscpfs.'"$1"'.'"$3"'.'"$2"'.log</string>'       >> $plist
echo '</dict>'                                                                        >> $plist
echo '</plist>'                                                                       >> $plist

ln -s $plist /Users/Shared/dcmtk/wlmscpfs/$1/wlmscpfs.$1.$3.$2.plist

start='/Users/Shared/dcmtk/wlmscpfs/'"$1"'/start.sh'
echo '#!/bin/sh'                                              >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                     >> $start
echo 'sudo -A launchctl load -w '"$plist"                     >> $start
echo 'sudo -A launchctl list | grep "wlmscpfs.'"$1"'.'"$3"'.'"$2"'"' >> $start

stop='/Users/Shared/dcmtk/wlmscpfs/'"$1"'/stop.sh'
echo '#!/bin/sh'                                              >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                     >> $stop
echo 'sudo -A launchctl unload -w '"$plist"                   >> $stop
echo 'sudo -A launchctl list | grep "wlmscpfs.'"$1"'.'"$3"'.'"$2"'"' >> $stop


chown -R pcs2:wheel /Users/Shared/dcmtk/wlmscpfs/$1
chmod -R 775 /Users/Shared/dcmtk/wlmscpfs/$1

fi
