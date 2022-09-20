#!/bin/bash

admin=$1
branch=$2
port=$3

mkdir -m 775 -p /Volumes/IN/$branch/{ARRIVED,CLASSIFIED,FAILURE,ORIGINALS,MISMATCH_ALTERNATES,MISMATCH_SOURCE,MISMATCH_CDAMWL,MISMATCH_PACS}
mkdir -m 775 -p '/Users/'"$admin"'/Documents/dcmtk'
mkdir -m 775 -p '/Users/Shared/dcmtk/storescp/'"$branch"

#x #a #r #p #f #c #d #t #h #e #n #s #i #k #m #y
classifier='/Users/Shared/dcmtk/storescp/'"$branch"'/classifier.sh'
echo '#!/bin/sh'                                              >  $classifier 
echo 'syntax=${1}  ;#x'                                       >> $classifier
echo 'scu=${2}     ;#a'                                       >> $classifier
echo 'scuip=${3}   ;#r'                                       >> $classifier
echo 'dir=${4}     ;#p'                                       >> $classifier
echo 'file=${5}    ;#f'                                       >> $classifier
echo 'scp=${6}     ;#c'                                       >> $classifier
echo 'Edate=${7}   ;#d'                                       >> $classifier
echo 'Etime=${8}   ;#t'                                       >> $classifier
echo 'Pid=${9}     ;#h'                                       >> $classifier
echo 'Euid=${10}   ;#e'                                       >> $classifier
echo 'Ean=${11}    ;#n'                                       >> $classifier
echo 'Suid=${12}   ;#s'                                       >> $classifier
echo 'Iuid=${13}   ;#i'                                       >> $classifier
echo 'Iclass=${14} ;#k'                                       >> $classifier
echo 'frames=${15} ;#m'                                       >> $classifier
echo 'chars=${16}  ;#y'                                       >> $classifier

echo 'if [[ syntax == "1.2.840.10008.1.2" ]];then'            >> $classifier
echo '   eic="I"'                                             >> $classifier
echo 'elif [[ syntax == "1.2.840.10008.1.2.1" ]];then'        >> $classifier
echo '   eic="E"'                                             >> $classifier
echo 'else'                                                   >> $classifier
echo '   eic="C"'                                             >> $classifier
echo 'fi'                                                     >> $classifier

echo 'base=/Volumes/IN/'"$branch"'/CLASSIFIED'                >> $classifier
echo 'device="$scu@$scuip^$eic^$scp"'                         >> $classifier
echo 'euid="$Pid@$Ean^$Euid"'                                 >> $classifier
echo 'suid="$Suid"'                                           >> $classifier

echo 'if [ ! -d "$base/$device/$euid/$suid" ];then '          >> $classifier
echo '   if [ ! -d "$base/$device/$euid" ];then '             >> $classifier
echo '       if [ ! -d "$base/$device/" ];then '              >> $classifier
echo '           mkdir -m 775 $base/$device'                  >> $classifier
echo '           chown '"$admin"':wheel $base/$device'        >> $classifier
echo '       fi'                                              >> $classifier
echo '       mkdir -m 775 $base/$device/$euid'                >> $classifier
echo '       chown '"$admin"':wheel $base/$device/$euid'      >> $classifier
echo '   fi' >> $classifier
echo '    mkdir -m 775 $base/$device/$euid/$suid'             >> $classifier
echo '    chown '"$admin"':wheel $base/$device/$euid/$suid'   >> $classifier
echo 'fi'                                                     >> $classifier

echo 'mv    $dir/$file $base/$device/$euid/$suid/$file'       >> $classifier
echo 'chmod 775        $base/$device/$euid/$suid/$file'       >> $classifier
echo 'chown '"$admin"':wheel $base/$device/$euid/$suid/$file' >> $classifier
chmod 755 $classifier

storescp='/Users/Shared/dcmtk/storescp/'"$branch"'/storescp.'"$branch"'.'"$port"'.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                                          >  $storescp
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $storescp
echo '<plist version="1.0">'                                                                           >> $storescp
echo '<dict>'                                                                                          >> $storescp
echo '    <key>Disabled</key>'                                                                         >> $storescp
echo '    <false/>'                                                                                    >> $storescp
echo '    <key>EnvironmentVariables</key>'                                                             >> $storescp
echo '    <dict>'                                                                                      >> $storescp
echo '        <key>DCMDICTPATH</key>'                                                                  >> $storescp
echo '        <string>/Users/Shared/dcmtk/dicom.dic</string>'                                          >> $storescp
echo '    </dict>'                                                                                     >> $storescp
echo '    <key>KeepAlive</key>'                                                                        >> $storescp
echo '    <true/>'                                                                                     >> $storescp
echo '    <key>Label</key>'                                                                            >> $storescp
echo '    <string>storescp.'"$branch"'.'"$port"'</string>'                                             >> $storescp
echo '    <key>ProgramArguments</key>'                                                                 >> $storescp
echo '    <array>'                                                                                     >> $storescp
echo '        <string>/usr/local/bin/storescp</string>'                                                >> $storescp
echo '        <string>-ll</string>'                                                                    >> $storescp
echo '        <string>warn</string>'                                                                   >> $storescp
echo '        <string>--fork</string>'                                                                 >> $storescp
echo '        <string>+xe</string>'                                                                    >> $storescp
echo '        <string>-pm</string>'                                                                    >> $storescp
echo '        <string>+te</string>'                                                                    >> $storescp
echo '        <string>-aet</string>'                                                                   >> $storescp
echo '        <string>'"$branch"'</string>'                                                            >> $storescp
echo '        <string>-pdu</string>'                                                                   >> $storescp
echo '        <string>131072</string>'                                                                 >> $storescp
echo '        <string>-dhl</string>'                                                                   >> $storescp
echo '        <string>-up</string>'                                                                    >> $storescp
echo '        <string>-g</string>'                                                                     >> $storescp
echo '        <string>-e</string>'                                                                     >> $storescp
echo '        <string>+uc</string>'                                                                    >> $storescp
echo '        <string>-od</string>'                                                                    >> $storescp
echo '        <string>/Volumes/IN/'"$branch"'/ARRIVED</string>'                                        >> $storescp
echo '        <string>-fe</string>'                                                                    >> $storescp
echo '        <string>'.dcm'</string>'                                                                 >> $storescp
echo '        <string>-su</string>'                                                                    >> $storescp
echo '        <string></string>'                                                                       >> $storescp
echo '        <string>-uf</string>'                                                                    >> $storescp
echo '        <string>-xcr</string>'                                                                   >> $storescp
echo '        <string>/Users/Shared/dcmtk/storescp/'"$branch"'/classifier.sh #x #a #r #p #f #c #d #t #h #e #n #s #i #k #m #y</string>'  >> $storescp
echo '        <string>'"$port"'</string>'                                                              >> $storescp
echo '    </array>'                                                                                    >> $storescp
echo '    <key>StandardErrorPath</key>'                                                                >> $storescp
echo '    <string>/Users/'"$admin"'/Documents/dcmtk/storescp.'"$branch"'.'"$port"'.error.log</string>' >> $storescp
echo '    <key>StandardOutPath</key>'                                                                  >> $storescp
echo '    <string>/Users/'"$admin"'/Documents/dcmtk/storescp.'"$branch"'.'"$port"'.log</string>'       >> $storescp
echo '</dict>'                                                                                         >> $storescp
echo '</plist>'                                                                                        >> $storescp
export SUDO_ASKPASS=/Users/Shared/pass.sh
sudo -A chmod 644 $storescp
sudo -A chown root:wheel $storescp
sudo -A mv $storescp /Library/LaunchDaemons/
ln -s '/Library/LaunchDaemons/storescp.'"$branch"'.'"$port"'.plist' $storescp



storescpARRIVEDrm='/Users/Shared/dcmtk/storescp/'"$branch"'/storescp.'"$branch"'.'"$port"'.ARRIVED.rm.plist'
echo '<?xml version="1.0" encoding="UTF-8"?>'                                 >  $storescpARRIVEDrm
echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $storescpARRIVEDrm
echo '<plist version="1.0">'                                          >> $storescpARRIVEDrm
echo '<dict>'                                                         >> $storescpARRIVEDrm
echo '    <key>Disabled</key>'                                        >> $storescpARRIVEDrm
echo '    <false/>'                                                   >> $storescpARRIVEDrm
echo '    <key>Label</key>'                                           >> $storescpARRIVEDrm
echo '    <string>storescp.'"$branch"'.'"$port"'.ARRIVED.rm</string>' >> $storescpARRIVEDrm
echo '    <key>ProgramArguments</key>'                                >> $storescpARRIVEDrm
echo '    <array>'                                                    >> $storescpARRIVEDrm
echo '        <string>find</string>'                                  >> $storescpARRIVEDrm
echo '        <string>/Volumes/IN/'"$branch"'/ARRIVED</string>'       >> $storescpARRIVEDrm
echo '        <string>-mtime</string>'                                >> $storescpARRIVEDrm
echo '        <string>+2</string>'                                    >> $storescpARRIVEDrm
echo '        <string>-empty</string>'                                >> $storescpARRIVEDrm
echo '        <string>-delete</string>'                               >> $storescpARRIVEDrm
echo '    </array>'                                                   >> $storescpARRIVEDrm
echo '    <key>StartCalenderInterval</key>'                           >> $storescpARRIVEDrm
echo '    <dict>'                                                     >> $storescpARRIVEDrm
echo '        <key>Hour</key>'                                        >> $storescpARRIVEDrm
echo '        <integer>01</integer>'                                  >> $storescpARRIVEDrm
echo '        <key>Minute</key>'                                      >> $storescpARRIVEDrm
echo '        <integer>00</integer>'                                  >> $storescpARRIVEDrm
echo '    </dict>'                                                    >> $storescpARRIVEDrm
echo '</dict>'                                                        >> $storescpARRIVEDrm
echo '</plist>'                                                       >> $storescpARRIVEDrm
export SUDO_ASKPASS=/Users/Shared/pass.sh
sudo -A chmod 644 $storescpARRIVEDrm
sudo -A chown root:wheel $storescpARRIVEDrm
sudo -A mv $storescpARRIVEDrm /Library/LaunchDaemons/
ln -s '/Library/LaunchDaemons/storescp.'"$branch"'.'"$port"'.ARRIVED.rm.plist' $storescpARRIVEDrm


start='/Users/Shared/dcmtk/storescp/'"$branch"'/start.sh'
echo '#!/bin/sh'                                                               >  $start
echo 'export SUDO_ASKPASS=/Users/Shared/pass.sh'                                      >> $start
echo 'sudo -A launchctl load -w '"$storescp"                                   >> $start
echo 'sudo -A launchctl load -w '"$storescpARRIVEDrm"                          >> $start
echo 'sudo -A launchctl list | grep storescp.'"$branch"'.'"$port"              >> $start
chmod 700 $start

stop='/Users/Shared/dcmtk/storescp/'"$branch"'/stop.sh'
echo '#!/bin/sh'                                                               >  $stop
echo 'export SUDO_ASKPASS=/Users/Shared/pass.sh'                               >> $stop
echo 'sudo -A launchctl unload -w '"$storescp"                                 >> $stop
echo 'sudo -A launchctl unload -w '"$storescpARRIVEDrm"                        >> $stop
echo 'sudo -A launchctl list | grep storescp.'"$branch"'.'"$port"              >> $stop
chmod 700 $stop

mkdir "/Users/Shared/dcmtk/storescp/storescp/storescp.$branch.$port"
storescpTest="/Users/Shared/dcmtk/storescp/storescp/storescp.$branch.$port.sh"
echo '#!/bin/bash' > $storescpTest
echo 'export SUDO_ASKPASS=/Users/Shared/pass.sh'                                      >> $storescpTest
echo "sudo -A /usr/local/bin/storescp -ll debug --fork +xe -pm +te -aet $branch -pdu 131072 -dhl -up -g -e -od /Users/Shared/dcmtk/storescp/storescp//storescp.$branch.$port  -fe '.dcm' -su \"\" -uf -xcr 'echo DIR____p: #p; echo FILE___f: #f; echo SCU____a: #a; echo SCP____c: #c; echo IP_____r: #r; echo TS_____x: #x; echo DA_____d: #d; echo TM_____t: #t; echo PID____h: #h; echo EUID___e: #e; echo AN_:___n: #n; echo SUID___s: #s; echo IUID___i: #i; echo CLASS__k: #k; echo FRAMES_m: #m; echo CHARS__y: #y; open #p/#f' $port" >> $storescpTest
chmod 700 $storescpTest

storescuTest="/Users/Shared/dcmtk/storescp/storescu/storescp.$branch.$port.sh"
echo '#!/bin/bash' > $storescuTest
echo "/usr/local/bin/storescu -xe -ll debug -R +C -aet test -aec $branch localhost $port /Users/Shared/dcmtk/storescp/storescu/ele.dcm" >> $storescuTest
chmod 700 $storescuTest
