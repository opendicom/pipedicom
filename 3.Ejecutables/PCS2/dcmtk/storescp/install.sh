#!/bin/bash
if [ "$#" -ne 4 ]; then
   echo 'dcmtk/storescp/install.sh'
   echo '$1 (admin)'
   echo '$2 (aet)'
   echo '$3 (port)'
else
admin=$1
aet=$2
port=$3



if [ ! -d "/Volumes/IN/$aet" ]
then
    mkdir -m 775 -p /Volumes/IN/$aet/{ARRIVED,CLASSIFIED,FAILURE,ORIGINALS,MISMATCH_ALTERNATES,MISMATCH_SOURCE,MISMATCH_CDAMWL,MISMATCH_PACS}
    chown -R $admin:wheel /Volumes/IN/$aet
fi



#log
if [ ! -d "/Users/$admin/Documents/dcmtk" ]
then
    mkdir -m 775 -p     /Users/$admin/Documents/dcmtk
    chown -R $admin:wheel /Users/$admin/Documents/dcmtk
fi



if [ ! -d "/Users/Shared/dcmtk/storescp/$aet" ]
then
    mkdir -m 775 -p /Users/Shared/dcmtk/storescp/$aet
fi


classifier="/Users/Shared/dcmtk/storescp/$aet/classifier.sh"
echo '#!/bin/sh'                                                    >  $classifier

echo '# $1=#a (calling aet)'                                        >> $classifier
echo '# $2=#r (calling presentation address)'                       >> $classifier
echo '# $3=#p (path/studyiuid)'                                     >> $classifier
echo '# $4=#f file name'                                            >> $classifier
echo '# $5=#c called aet'                                           >> $classifier

echo 'base=/Volumes/IN/'"$aet"'/CLASSIFIED'                         >> $classifier
echo 'device="$1@$2^$5"'                                            >> $classifier
echo 'euid="${3##*/}"'                                              >> $classifier

echo 'dcm=$(head -c 30000 $3/$4  | tail -c 29000))'                 >> $classifier
echo 'posteuid=${dcm#*$euid}'                                       >> $classifier
echo 'suidattr=${posteuid:5:64}'                                    >> $classifier
echo 'suid=${suidattr%%[[:space:]]*}'                               >> $classifier

echo 'if [ ! -d "$base/$device/$euid/$suid" ]'                      >> $classifier
echo 'then'                                                         >> $classifier
echo '    if [ ! -d "$base/$device/$euid" ]'                        >> $classifier
echo '    then'                                                     >> $classifier
echo '        if [ ! -d "$base/$device" ]'                          >> $classifier
echo '        then'                                                 >> $classifier
echo '            mkdir -m 775 $base/$device'                       >> $classifier
echo '            chown '"$admin"':wheel $base/$device'             >> $classifier
echo '        fi'                                                   >> $classifier
echo '        mkdir -m 775 $base/$device/$euid'                     >> $classifier
echo '        chown '"$admin"':wheel $base/$device/$euid'           >> $classifier
echo '    fi'                                                       >> $classifier
echo '    mkdir -m 775 $base/$device/$euid/$suid'                   >> $classifier
echo '    chown '"$admin"':wheel $base/$device/$euid/$suid'         >> $classifier
echo 'fi'                                                           >> $classifier

echo 'mv    $3/$4            $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier
echo 'chmod 775              $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier
echo 'chown '"$admin"':wheel $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier


$storescp='/Library/LaunchDaemons/storescp.'"$aet"'.'"$port"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                       >  $$storescp
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                           >> $$storescp
echo '<plist version="1.0">'                                                                        >> $$storescp
echo '<dict>'                                                                                       >> $$storescp
echo '    <key>Disabled</key>'                                                                      >> $$storescp
echo '    <false/>'                                                                                 >> $$storescp
echo '    <key>EnvironmentVariables</key>'                                                          >> $$storescp
echo '    <dict>'                                                                                   >> $$storescp
echo '        <key>DCMDICTPATH</key>'                                                               >> $$storescp
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                       >> $$storescp
echo '    </dict>'                                                                                  >> $$storescp
echo '    <key>KeepAlive</key>'                                                                     >> $$storescp
echo '    <true/>'                                                                                  >> $$storescp
echo '    <key>Label</key>'                                                                         >> $$storescp
echo '    <string>storescp.'"$aet"'.'"$port"'</string>'                                             >> $$storescp
echo '    <key>ProgramArguments</key>'                                                              >> $$storescp
echo '    <array>'                                                                                  >> $$storescp
echo '        <string>/usr/local/bin/storescp</string>'                                             >> $$storescp
echo '        <string>-ll</string>'                                                                 >> $$storescp
echo '        <string>warn</string>'                                                                >> $$storescp
echo '        <string>--fork</string>'                                                              >> $$storescp
echo '        <string>+xe</string>'                                                                 >> $$storescp
echo '        <string>-pm</string>'                                                                 >> $$storescp
echo '        <string>+te</string>'                                                                 >> $$storescp
echo '        <string>-aet</string>'                                                                >> $$storescp
echo '        <string>'"$aet"'</string>'                                                            >> $$storescp
echo '        <string>-pdu</string>'                                                                >> $$storescp
echo '        <string>131072</string>'                                                              >> $$storescp
echo '        <string>-dhl</string>'                                                                >> $$storescp
echo '        <string>-up</string>'                                                                 >> $$storescp
echo '        <string>-g</string>'                                                                  >> $$storescp
echo '        <string>-e</string>'                                                                  >> $$storescp
echo '        <string>-od</string>'                                                                 >> $$storescp
echo '        <string>/Volumes/IN/'"$aet"'/ARRIVED</string>'                                        >> $$storescp
echo '        <string>-su</string>'                                                                 >> $$storescp
echo '        <string></string>'                                                                    >> $$storescp
echo '        <string>-uf</string>'                                                                 >> $$storescp
echo '        <string>-xcr</string>'                                                                >> $$storescp
echo '        <string>/Users/Shared/dcmtk/storescp/'"$aet"'/classifier.sh #a #r #p #f #c</string>'  >> $$storescp
echo '        <string>'"$port"'</string>'                                                           >> $$storescp
echo '    </array>'                                                                                 >> $$storescp
echo '    <key>StandardErrorPath</key>'                                                             >> $$storescp
echo '    <string>/Users/'"$admin"'/Documents/dcmtk/storescp.'"$aet"'.'"$port"'.error.log</string>' >> $$storescp
echo '    <key>StandardOutPath</key>'                                                               >> $$storescp
echo '    <string>/Users/'"$admin"'/Documents/dcmtk/storescp.'"$aet"'.'"$port"'.log</string>'       >> $$storescp
echo '</dict>'                                                                                      >> $$storescp
echo '</plist>'                                                                                     >> $$storescp

ln -s $$storescp /Users/Shared/dcmtk/storescp/$aet/storescp.$aet.$port.plist



start='/Users/Shared/dcmtk/storescp/'"$aet"'/start.sh'
echo '#!/bin/sh'                                                   >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                          >> $start
echo 'sudo -A launchctl load -w '"$storescp"                       >> $start
echo 'sudo -A launchctl list | grep "storescp.'"$aet"'.'"$port"'"' >> $start

stop='/Users/Shared/dcmtk/storescp/'"$aet"'/stop.sh'
echo '#!/bin/sh'                                                   >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                          >> $stop
echo 'sudo -A launchctl unload -w '"$storescp"                     >> $stop
echo 'sudo -A launchctl list | grep "storescp.'"$aet"'.'"$port"'"' >> $stop


#permisos /Users/Shared/dcmtk/storescp/$aet
chown -R $admin:wheel /Users/Shared/dcmtk/storescp/$aet
chmod -R 775 /Users/Shared/dcmtk/storescp/$aet

fi
