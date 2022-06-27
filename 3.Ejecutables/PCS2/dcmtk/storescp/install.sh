#!/bin/bash
if [ "$#" -ne 3 ]; then
   echo 'dcmtk/storescp/install'
   echo '$1= (pcs aet)'
   echo '$2= (pcs port)'
   echo '$3= (admin user name)'
else

if [ ! -d "/Users/Shared/dcmtk/storescp/$1" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/storescp/$1
fi

if [ ! -d "/Volumes/IN/$1" ]
then
    mkdir -m 775 -p /Volumes/IN/$1/{ARRIVED,CLASSIFIED,FAILURE,MISMATCH_CDAMWL,MISMATCH_PACS,MISMATCH_SOURCE,ORIGINALS}
    chown -R $3:wheel /Volumes/IN/$1
fi

#log
if [ ! -d "/Users/$3/Documents/dcmtk" ]
then
    mkdir -m 775 -p     /Users/$3/Documents/dcmtk
    chown -R $3:wheel /Users/$3/Documents/dcmtk
fi
ln -s /Users/$3/Documents/dcmtk /Users/Shared/dcmtk/storescp/$1/log


classifier="/Users/Shared/dcmtk/storescp/$1/classifier.sh"
echo '#!/bin/sh'                                                >  $classifier
echo '# $1=#a (calling aet)'                                    >> $classifier
echo '# $2=#r (calling presentation address)'                   >> $classifier
echo '# $3=#p (path/studyiuid)'                                 >> $classifier
echo '# $4=#f file name'                                        >> $classifier

echo 'base=/Volumes/IN/'"$1"'/CLASSIFIED'                       >> $classifier
echo 'device="${4%%.*}@$1@$2"'                                  >> $classifier
echo 'euid="${3##*/}"'                                          >> $classifier

echo 'dcm=$(head -c 4095 $3/$4)'                                >> $classifier
echo 'posteuid=${dcm#*$euid}'                                   >> $classifier
echo 'suidattr=${posteuid:5:64}'                                >> $classifier
echo 'suid=${suidattr%%[[:space:]]*}'                           >> $classifier

echo 'if [ ! -d "$base/$device/$euid/$suid" ]'                  >> $classifier
echo 'then'                                                     >> $classifier
echo '    if [ ! -d "$base/$device/$euid" ]'                    >> $classifier
echo '    then'                                                 >> $classifier
echo '        if [ ! -d "$base/$device" ]'                      >> $classifier
echo '        then'                                             >> $classifier
echo '            mkdir -m 775 $base/$device'                   >> $classifier
echo '            chown '"$3"':wheel $base/$device'             >> $classifier
echo '        fi'                                               >> $classifier
echo '        mkdir -m 775 $base/$device/$euid'                 >> $classifier
echo '        chown '"$3"':wheel $base/$device/$euid'           >> $classifier
echo '    fi'                                                   >> $classifier
echo '    mkdir -m 775 $base/$device/$euid/$suid'               >> $classifier
echo '    chown '"$3"':wheel $base/$device/$euid/$suid'         >> $classifier
echo 'fi'                                                       >> $classifier

echo 'mv    $3/$4        $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier
echo 'chmod 775          $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier
echo 'chown '"$3"':wheel $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier


plist='/Library/LaunchDaemons/storescp.'"$1"'.'"$2"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                 >  $plist
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                                        >> $plist
echo '<plist version="1.0">'                                                                  >> $plist
echo '<dict>'                                                                                 >> $plist
echo '    <key>Disabled</key>'                                                                >> $plist
echo '    <false/>'                                                                           >> $plist
echo '    <key>EnvironmentVariables</key>'                                                    >> $plist
echo '    <dict>'                                                                             >> $plist
echo '        <key>DCMDICTPATH</key>'                                                         >> $plist
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                 >> $plist
echo '    </dict>'                                                                            >> $plist
echo '    <key>KeepAlive</key>'                                                               >> $plist
echo '    <true/>'                                                                            >> $plist
echo '    <key>Label</key>'                                                                   >> $plist
echo '    <string>storescp.'"$1"'.'"$2"'.plist</string>'                                      >> $plist
echo '    <key>ProgramArguments</key>'                                                        >> $plist
echo '    <array>'                                                                            >> $plist
echo '        <string>/usr/local/bin/storescp</string>'                                       >> $plist
echo '        <string>-ll</string>'                                                           >> $plist
echo '        <string>warn</string>'                                                          >> $plist
echo '        <string>--fork</string>'                                                        >> $plist
echo '        <string>+xe</string>'                                                           >> $plist
echo '        <string>-pm</string>'                                                           >> $plist
echo '        <string>+te</string>'                                                           >> $plist
echo '        <string>-aet</string>'                                                          >> $plist
echo '        <string>'"$1"'</string>'                                                        >> $plist
echo '        <string>-pdu</string>'                                                          >> $plist
echo '        <string>131072</string>'                                                        >> $plist
echo '        <string>-dhl</string>'                                                          >> $plist
echo '        <string>-up</string>'                                                           >> $plist
echo '        <string>-g</string>'                                                            >> $plist
echo '        <string>-e</string>'                                                            >> $plist
echo '        <string>-od</string>'                                                           >> $plist
echo '        <string>/Volumes/IN/'"$1"'/ARRIVED</string>'                                    >> $plist
echo '        <string>-su</string>'                                                           >> $plist
echo '        <string></string>'                                                              >> $plist
echo '        <string>-uf</string>'                                                           >> $plist
echo '        <string>-xcr</string>'                                                          >> $plist
echo '        <string>/Users/Shared/dcmtk/storescp/'"$1"'/classifier.sh #a #r #p #f #c</string>' >> $plist
echo '        <string>'"$2"'</string>'                                                        >> $plist
echo '    </array>'                                                                           >> $plist
echo '    <key>StandardErrorPath</key>'                                                       >> $plist
echo '    <string>/Users/$3/Documents/dcmtk/storescp.'"$1"'.'"$2"'.error.log</string>'        >> $plist
echo '    <key>StandardOutPath</key>'                                                         >> $plist
echo '    <string>/Users/$3/Documents/dcmtk/storescp.'"$1"'.'"$2"'.log</string>'              >> $plist
echo '</dict>'                                                                                >> $plist
echo '</plist>'                                                                               >> $plist

ln -s $plist /Users/Shared/dcmtk/storescp/$1/storescp.$1.$2.plist



start='/Users/Shared/dcmtk/storescp/'"$1"'/start.sh'
echo '#!/bin/sh'                                              >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                     >> $start
echo 'sudo -A launchctl load -w '"$plist"                     >> $start
echo 'sudo -A launchctl list | grep "storescp.'"$1"'.'"$2"'"' >> $start

stop='/Users/Shared/dcmtk/storescp/'"$1"'/stop.sh'
echo '#!/bin/sh'                                              >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                     >> $stop
echo 'sudo -A launchctl unload -w '"$plist"                   >> $stop
echo 'sudo -A launchctl list | grep "storescp.'"$1"'.'"$2"'"' >> $stop


#permisos /Users/Shared/dcmtk/storescp/$1
chown -R $3:wheel /Users/Shared/dcmtk/storescp/$1
chmod -R 775 /Users/Shared/dcmtk/storescp/$1

fi
