#!/bin/bash

admin=$1
branch=$2
port=$3

mkdir -m 775 -p /Volumes/IN/$branch/{ARRIVED,CLASSIFIED,FAILURE,ORIGINALS,MISMATCH_ALTERNATES,MISMATCH_SOURCE,MISMATCH_CDAMWL,MISMATCH_PACS}
mkdir -m 775 -p     '/Users/'"$admin"'/Documents/dcmtk'
mkdir -m 775 -p '/Users/Shared/dcmtk/storescp/'"$branch"


classifier='/Users/Shared/dcmtk/storescp/'"$branch"'/classifier.sh'
echo '#!/bin/sh'                       >  $classifier
echo 'callingaet=${1}  ;#a'            >> $classifier
echo 'callingip=${2}   ;#r'            >> $classifier
echo 'dirpath=${3}     ;#p'            >> $classifier
echo 'filename=${4}    ;#f'            >> $classifier
echo 'calledaet=${5}   ;#c'            >> $classifier
echo 'Edate=${6}       ;#d'            >> $classifier
echo 'Etime=${7}       ;#t'            >> $classifier
echo 'Pid=${8}         ;#h'            >> $classifier
echo 'Euid=${9}        ;#e'            >> $classifier
echo 'Ean=${10}        ;#n'            >> $classifier
echo 'Suid=${11}       ;#s'            >> $classifier
echo 'Iuid=${12}       ;#i'            >> $classifier
echo 'Iclass=${13}     ;#k'            >> $classifier
echo 'multiframe=${14} ;#m'            >> $classifier
echo 'base=/Volumes/IN/'"$branch"'/CLASSIFIED/$callingaet@$callingip^$calledaet/$Pid@$Ean^$Euid/$Suid' >> $classifier
echo 'mkdir -m 775 -p $base'           >> $classifier
echo 'Ipath=$base/$Iuid.dcm'           >> $classifier
echo 'mv    $dirpath/$filename $Ipath' >> $classifier
echo 'chmod 775                $Ipath' >> $classifier
echo 'chown '"$admin"':wheel   $Ipath' >> $classifier

exit

export SUDO_ASKPASS=/Users/Shared/pass.sh

storescp='/Library/LaunchDaemons/storescp.'"$branch"'.'"$port"'.plist'
sudo -A echo '<?xml version="1.0" encoding="UTF-8"?>'                                                       >  $storescp
sudo -A echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                           >> $storescp
sudo -A echo '<plist version="1.0">'                                                                        >> $storescp
sudo -A echo '<dict>'                                                                                       >> $storescp
sudo -A echo '    <key>Disabled</key>'                                                                      >> $storescp
sudo -A echo '    <false/>'                                                                                 >> $storescp
sudo -A echo '    <key>EnvironmentVariables</key>'                                                          >> $storescp
sudo -A echo '    <dict>'                                                                                   >> $storescp
sudo -A echo '        <key>DCMDICTPATH</key>'                                                               >> $storescp
sudo -A echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                       >> $storescp
sudo -A echo '    </dict>'                                                                                  >> $storescp
sudo -A echo '    <key>KeepAlive</key>'                                                                     >> $storescp
sudo -A echo '    <true/>'                                                                                  >> $storescp
sudo -A echo '    <key>Label</key>'                                                                         >> $storescp
sudo -A echo '    <string>storescp.'"$branch"'.'"$port"'</string>'                                             >> $storescp
sudo -A echo '    <key>ProgramArguments</key>'                                                              >> $storescp
sudo -A echo '    <array>'                                                                                  >> $storescp
sudo -A echo '        <string>/usr/local/bin/storescp</string>'                                             >> $storescp
sudo -A echo '        <string>-ll</string>'                                                                 >> $storescp
sudo -A echo '        <string>warn</string>'                                                                >> $storescp
sudo -A echo '        <string>--fork</string>'                                                              >> $storescp
sudo -A echo '        <string>+xe</string>'                                                                 >> $storescp
sudo -A echo '        <string>-pm</string>'                                                                 >> $storescp
sudo -A echo '        <string>+te</string>'                                                                 >> $storescp
sudo -A echo '        <string>-aet</string>'                                                                >> $storescp
sudo -A echo '        <string>'"$branch"'</string>'                                                            >> $storescp
sudo -A echo '        <string>-pdu</string>'                                                                >> $storescp
sudo -A echo '        <string>131072</string>'                                                              >> $storescp
sudo -A echo '        <string>-dhl</string>'                                                                >> $storescp
sudo -A echo '        <string>-up</string>'                                                                 >> $storescp
sudo -A echo '        <string>-g</string>'                                                                  >> $storescp
sudo -A echo '        <string>-e</string>'                                                                  >> $storescp
sudo -A echo '        <string>+uc</string>'                                                                 >> $storescp
sudo -A echo '        <string>-od</string>'                                                                 >> $storescp
sudo -A echo '        <string>/Volumes/IN/'"$branch"'/ARRIVED</string>'                                        >> $storescp
sudo -A echo '        <string>-su</string>'                                                                 >> $storescp
sudo -A echo '        <string></string>'                                                                    >> $storescp
sudo -A echo '        <string>-uf</string>'                                                                 >> $storescp
sudo -A echo '        <string>-xcr</string>'                                                                >> $storescp
sudo -A echo '        <string>/Users/Shared/dcmtk/storescp/'"$branch"'/classifier.sh #a #r #p #f #c #d #t #h #e #n #s #i #k #m</string>'  >> $storescp
sudo -A echo '        <string>'"$port"'</string>'                                                           >> $storescp
sudo -A echo '    </array>'                                                                                 >> $storescp
sudo -A echo '    <key>StandardErrorPath</key>'                                                             >> $storescp
sudo -A echo '    <string>/Users/'"$admin"'/Documents/dcmtk/storescp.'"$branch"'.'"$port"'.error.log</string>' >> $storescp
sudo -A echo '    <key>StandardOutPath</key>'                                                               >> $storescp
sudo -A echo '    <string>/Users/'"$admin"'/Documents/dcmtk/storescp.'"$branch"'.'"$port"'.log</string>'       >> $storescp
sudo -A echo '</dict>'                                                                                      >> $storescp
sudo -A echo '</plist>'                                                                                     >> $storescp

if [ ! -d '/Users/Shared/dcmtk/storescp/'"$branch"'/storescp.'"$branch"'.'"$port"'.plist' ]
then
   ln -s "$storescp" '/Users/Shared/dcmtk/storescp/'"$branch"'/storescp.'"$branch"'.'"$port"'.plist'
fi


start='/Users/Shared/dcmtk/storescp/'"$branch"'/start.sh'
echo '#!/bin/sh'                                               >  $start
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                      >> $start
echo 'sudo -A launchctl load -w '"$storescp"                   >> $start
echo 'sudo -A launchctl list | grep storescp.'"$branch"'.'"$port" >> $start

stop='/Users/Shared/dcmtk/storescp/'"$branch"'/stop.sh'
echo '#!/bin/sh'                                               >  $stop
echo 'SUDO_ASKPASS=/Users/Shared/pass.sh'                      >> $stop
echo 'sudo -A launchctl unload -w '"$storescp"                 >> $stop
echo 'sudo -A launchctl list | grep storescp.'"$branch"'.'"$port" >> $stop


#permisos /Users/Shared/dcmtk/storescp/$branch
chown -R "$admin":wheel '/Users/Shared/dcmtk/storescp/'"$branch"
chmod -R 775 '/Users/Shared/dcmtk/storescp/'"$branch"
