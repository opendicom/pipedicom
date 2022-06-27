#!/bin/bash
# $1= (aet to send to)
# $2= "https://serviciosridi.asse.uy/dcm4chee-arc/stow/DCM4CHEE/studies"

if [ "$#" -ne 4 ]; then
   echo 'opendicom/storedicom/install.sh'
   echo '$1= (pacs aet)'
   echo '$2= (pacs url)'
   echo '$3= (admin user name)'
else

if [ ! -d "/Users/Shared/opendicom/storedicom/$1" ]
then
    mkdir -m 775 -p /Users/Shared/opendicom/storedicom/$1
fi

if [ ! -d "/Volumes/IN/$1" ]
then
    mkdir -m 775 -p /Volumes/IN/$1/{SEND,MISMATCH_SERVICE,SENT,LOG,BATCHES}
    chown -R $3:wheel /Volumes/IN/$1
fi

if [ ! -d "/Users/$3/Documents/opendicom" ]
then
    mkdir -m 775 /Users/$3/Documents/opendicom
    chown -R $3:wheel /Users/$3/Documents/opendicom
fi

plist='/Users/pcs2/Library/LaunchAgents/storedicom.'"$1"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                           >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                  >> $plist
echo '<plist version="1.0">'                                                            >> $plist
echo '<dict>'                                                                           >> $plist
echo '    <key>Label</key>'                                                             >> $plist
echo '    <string>storedicom.plist</string>'                                            >> $plist
echo '    <key>ProgramArguments</key>'                                                  >> $plist
echo '    <array>'                                                                      >> $plist
echo '        <string>sh</string>'                                                      >> $plist
echo '        <string>/Users/Shared/opendicom/storedicom/storedicom.sh</string>'        >> $plist
echo '        <string>/Volumes/IN/'"$1"'</string>'                                      >> $plist
echo '        <string>'"$2"'</string>'                                                  >> $plist
echo '        <string>/Users/Shared/opendicom/storedicom/respParsing</string>'          >> $plist
echo '    </array>'                                                                     >> $plist
echo '    <key>StandardErrorPath</key>'                                                 >> $plist
echo '    <string>/Users/pcs2/Documents/opendicom/storedicom.'"$1"'.error.log</string>' >> $plist
echo '    <key>StandardOutPath</key>'                                                   >> $plist
echo '    <string>/Users/pcs2/Documents/opendicom/storedicom.'"$1"'.log</string>'       >> $plist
echo '    <key>StartInterval</key>'                                                     >> $plist
echo '    <integer>60</integer>'                                                        >> $plist
echo '    <key>Umask</key>'                                                             >> $plist
echo '    <integer>0</integer>'                                                         >> $plist
echo '</dict>'                                                                          >> $plist
echo '</plist>'                                                                         >> $plist

ln -s $plist /Users/Shared/opendicom/storedicom/$1/storedicom.$1.plist


start='/Users/Shared/opendicom/storedicom/'"$1"'/start.sh'
echo '#!/bin/sh'                          >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh' >> $start
echo 'launchctl load -w '"$plist"         >> $start
echo 'launchctl list | grep "storedicom"' >> $start

stop='/Users/Shared/opendicom/storedicom/'"$1"'/stop.sh'
echo '#!/bin/sh'                          >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh' >> $stop
echo 'launchctl unload -w '"$plist"       >> $stop
echo 'launchctl list | grep "storedicom"' >> $stop


chown -R $3:wheel   /Users/Shared/opendicom/storedicom/$1
chmod -R 775        /Users/Shared/opendicom/storedicom/$1

fi
