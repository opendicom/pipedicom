#!/bin/bash

ADMIN=$1
AET=$2
PORT=$3



if [ ! -d "/Volumes/IN/$AET" ]
then
    mkdir -m 775 -p "/Volumes/IN/$AET/{ARRIVED,CLASSIFIED,FAILURE,ORIGINALS,MISMATCH_ALTERNATES,MISMATCH_SOURCE,MISMATCH_CDAMWL,MISMATCH_PACS}"
    chown -R "$ADMIN":wheel "/Volumes/IN/$AET"
fi



#log
if [ ! -d "/Users/$ADMIN/Documents/dcmtk" ]
then
    mkdir -m 775 -p     "/Users/$ADMIN/Documents/dcmtk"
    chown -R "$ADMIN":wheel "/Users/$ADMIN/Documents/dcmtk"
fi



if [ ! -d "/Users/Shared/dcmtk/storescp/$AET" ]
then
    mkdir -m 775 -p "/Users/Shared/dcmtk/storescp/$AET"
fi


classifier="/Users/Shared/dcmtk/storescp/$AET/classifier.sh"
echo '#!/bin/sh'                                                    >  $classifier

echo '# $1=#a (calling AET)'                                        >> $classifier
echo '# $2=#r (calling presentation address)'                       >> $classifier
echo '# $3=#p (path/studyiuid)'                                     >> $classifier
echo '# $4=#f file name'                                            >> $classifier
echo '# $5=#c called AET'                                           >> $classifier

echo 'base=/Volumes/IN/'"$AET"'/CLASSIFIED'                         >> $classifier
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
echo '            chown '"$ADMIN"':wheel $base/$device'             >> $classifier
echo '        fi'                                                   >> $classifier
echo '        mkdir -m 775 $base/$device/$euid'                     >> $classifier
echo '        chown '"$ADMIN"':wheel $base/$device/$euid'           >> $classifier
echo '    fi'                                                       >> $classifier
echo '    mkdir -m 775 $base/$device/$euid/$suid'                   >> $classifier
echo '    chown '"$ADMIN"':wheel $base/$device/$euid/$suid'         >> $classifier
echo 'fi'                                                           >> $classifier

echo 'mv    $3/$4            $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier
echo 'chmod 775              $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier
echo 'chown '"$ADMIN"':wheel $base/$device/$euid/$suid/${4#*.}.dcm' >> $classifier


storescp='/Library/LaunchDaemons/storescp.'"$AET"'.'"$PORT"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                       >  $storescp
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                           >> $storescp
echo '<plist version="1.0">'                                                                        >> $storescp
echo '<dict>'                                                                                       >> $storescp
echo '    <key>Disabled</key>'                                                                      >> $storescp
echo '    <false/>'                                                                                 >> $storescp
echo '    <key>EnvironmentVariables</key>'                                                          >> $storescp
echo '    <dict>'                                                                                   >> $storescp
echo '        <key>DCMDICTPATH</key>'                                                               >> $storescp
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                       >> $storescp
echo '    </dict>'                                                                                  >> $storescp
echo '    <key>KeepAlive</key>'                                                                     >> $storescp
echo '    <true/>'                                                                                  >> $storescp
echo '    <key>Label</key>'                                                                         >> $storescp
echo '    <string>storescp.'"$AET"'.'"$PORT"'</string>'                                             >> $storescp
echo '    <key>ProgramArguments</key>'                                                              >> $storescp
echo '    <array>'                                                                                  >> $storescp
echo '        <string>/usr/local/bin/storescp</string>'                                             >> $storescp
echo '        <string>-ll</string>'                                                                 >> $storescp
echo '        <string>warn</string>'                                                                >> $storescp
echo '        <string>--fork</string>'                                                              >> $storescp
echo '        <string>+xe</string>'                                                                 >> $storescp
echo '        <string>-pm</string>'                                                                 >> $storescp
echo '        <string>+te</string>'                                                                 >> $storescp
echo '        <string>-aet</string>'                                                                >> $storescp
echo '        <string>'"$AET"'</string>'                                                            >> $storescp
echo '        <string>-pdu</string>'                                                                >> $storescp
echo '        <string>131072</string>'                                                              >> $storescp
echo '        <string>-dhl</string>'                                                                >> $storescp
echo '        <string>-up</string>'                                                                 >> $storescp
echo '        <string>-g</string>'                                                                  >> $storescp
echo '        <string>-e</string>'                                                                  >> $storescp
echo '        <string>-od</string>'                                                                 >> $storescp
echo '        <string>/Volumes/IN/'"$AET"'/ARRIVED</string>'                                        >> $storescp
echo '        <string>-su</string>'                                                                 >> $storescp
echo '        <string></string>'                                                                    >> $storescp
echo '        <string>-uf</string>'                                                                 >> $storescp
echo '        <string>-xcr</string>'                                                                >> $storescp
echo '        <string>/Users/Shared/dcmtk/storescp/'"$AET"'/classifier.sh #a #r #p #f #c</string>'  >> $storescp
echo '        <string>'"$PORT"'</string>'                                                           >> $storescp
echo '    </array>'                                                                                 >> $storescp
echo '    <key>StandardErrorPath</key>'                                                             >> $storescp
echo '    <string>/Users/'"$ADMIN"'/Documents/dcmtk/storescp.'"$AET"'.'"$PORT"'.error.log</string>' >> $storescp
echo '    <key>StandardOutPath</key>'                                                               >> $storescp
echo '    <string>/Users/'"$ADMIN"'/Documents/dcmtk/storescp.'"$AET"'.'"$PORT"'.log</string>'       >> $storescp
echo '</dict>'                                                                                      >> $storescp
echo '</plist>'                                                                                     >> $storescp

if [ ! -d "/Users/Shared/dcmtk/storescp/$AET/storescp.$AET.$PORT.plist" ]
then
   ln -s "$storescp" "/Users/Shared/dcmtk/storescp/$AET/storescp.$AET.$PORT.plist"
fi


start='/Users/Shared/dcmtk/storescp/'"$AET"'/start.sh'
echo '#!/bin/sh'                                                   >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                          >> $start
echo 'sudo -A launchctl load -w '"storescp"                        >> $start
echo 'sudo -A launchctl list | grep "storescp.'"$AET"'.'"$PORT"'"' >> $start

stop='/Users/Shared/dcmtk/storescp/'"$AET"'/stop.sh'
echo '#!/bin/sh'                                                   >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                          >> $stop
echo 'sudo -A launchctl unload -w '"storescp"                      >> $stop
echo 'sudo -A launchctl list | grep "storescp.'"$AET"'.'"$PORT"'"' >> $stop


#permisos /Users/Shared/dcmtk/storescp/$AET
chown -R "$ADMIN":wheel "/Users/Shared/dcmtk/storescp/$AET"
chmod -R 775 "/Users/Shared/dcmtk/storescp/$AET"
