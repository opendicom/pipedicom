#!/usr/bin/env bash

#  stdin | uidb64 | stdout +status

#  Created by jacquesfauquex on 2022-08-25.

#  converts uid into its reduced form uidb64
#  =========================================
#  - each character is transformed in half byte
#  - the resulting stream is then transformed in a
#  special base64, friendly to urls
#  (which does not contain the reserved chars / or =)

# supports space separated lists of uids
# ======================================
# in this case returns 0 if everything worked well

# alternatively, interprets one DICOMweb url
# ==========================================
# https://www.dicomstandard.org/using/dicomweb/restful-structure

# with an opcional prefix (for instance StudyDate aaaammdd

#  - [0-9.]{0,64}/studies/{uida}[/series/{uidb}[/instance/{uidc}]]

#  -- [0-9.]{0,64}/uidb64a[/uidb64b[/uidb64c]]
# returns after the first url with code precising url type
#declare -A exitValue=( [bad]=-1 [end]=0 [uid]=1 [url]=2 [query]=3 [rendered]=4 [metadata]=5 [frames]=6 )

b64=( - 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z _ a b c d e f g h i j k l m n o p q r s t u v w x y z )

#hb=half byte (0-15)
#declare hb2char=( 1.2.840.10008. . 0. 0 1. 1 2. 2 3. 3 4 5 6 7 8 9 )
declare -A simplechar2hb=( [.]=0x01 [4]=0x0A [5]=0x0B [6]=0x0C [7]=0x0D [8]=0x0E [9]=0x0F )
declare -A specialchar2hb=( [1.2.840.10008.]=0x00 [0.]=0x02 [0]=0x03 [1.]=0x04 [1]=0x05 [2.]=0x06 [2]=0x07 [3.]=0x08 [3]=0x09 )

function hb2b64 {
    local -n hb=$1  # use nameref for indirection
    
   [[ ${#hb[@]} -gt 64 ]] && exit -1
   #is aproximate (because of x. optimizations)

    # padding with .. in case of hb%3 != 0
    hb+=(0x01)
    hb+=(0x01)
#echo "${hb[@]}"
    # 3 half bytes transformed into 2 base64 chars
    let "hbCount=(( ${#hb[@]} / 3 ) *3)"
    for (( j=0; j<$hbCount; j+=3 ))
    do
      # "aaaa bb""bb cccc"
      echo -n "${b64[$(( (${hb[$j]} << 2) + (${hb[$j+1]} >> 2) ))]}""${b64[$((( (${hb[$j+1]} & 0x03) << 4) + ${hb[$j+2]} ))]}"
    done
    hb=()
}

#==================== main ====================

while read line; do
    for word in $line; do
#echo $word
wordLength=${#word}
studiesOffset=0
seriesOffset=0
instancesOffset=0

halfBytes=() # partial result (before base64)

#for each char, case unknown, case /, case \, or case .0123456789
for (( i=0; i<${#word}; i++ ))
do
#echo 'half bytes:'"${halfBytes[@]}"
   curChar=${word:$i:1}
#echo 'cur char:'$curChar

case $curChar in


   . | 4 | 5 | 6 | 7 | 8 | 9)
      halfBytes+=(${simplechar2hb[$curChar]})
   ;;


   0 | 1 | 2 | 3)
      wordRemaining=${word:$i:(($wordLength-$i))}
      if [[ $wordRemaining == 1.2.840.10008.* ]]; then
         curChar='1.2.840.10008.'
         i=$(($i+13))
      elif [[ $wordRemaining == $curChar.* ]]; then
         curChar="$curChar"'.'
         i=$(($i+1))
      fi
      halfBytes+=(${specialchar2hb[$curChar]})
   ;;


   /)
      wordRemaining=${word:$i:(($wordLength-$i))}
#echo -n '<'"$wordRemaining"'>'
      if [[ $studiesOffset == 0 ]]; then
         [[ $wordRemaining != /studies/* ]] && echo esperaba studies #exit -1
         studiesOffset=$(($i+9))
         i=$(($i+8))
         hb2b64 halfBytes
         echo -n '/'
      elif [[ $seriesOffset == 0 ]]; then
         [[ $wordRemaining != /series/* ]] && echo esperaba series # exit -1
         seriesOffset=$(($i+8))
         i=$(($i+7))
         hb2b64 halfBytes
         echo -n '/'
      elif [[ $instancesOffset == 0 ]]; then
         [[ $wordRemaining != /instances/* ]] && echo esperaba instances #exit -1
         instancesOffset=$(($i+11))
         i=$(($i+10))
         hb2b64 halfBytes
         echo -n '/'
      elif [[ $wordRemaining == /rendered ]]; then
         hb2b64 halfBytes
         echo ""
         exit 4
      elif [[ $wordRemaining == /metadata ]]; then
         hb2b64 halfBytes
         echo ""
         exit 5
      elif [[ $wordRemaining == /frames ]]; then
         hb2b64 halfBytes
         echo ""
         exit 6
      elif [[ $wordRemaining == /* ]]; then
#echo slash no contemplado
         exit -1
      fi
      ;;


   ?)
      [[ studiesOffset==0 ]] && exit -1
      hb2b64 halfBytes
      exit 2; #url
      ;;


   *)
      exit -1
      ;;
esac

done #curChar
[[ ${#halfBytes[@]} -gt 0 ]] && hb2b64 halfBytes

[[ $studiesOffset != 0 ]] && exit 2; #one url only

echo " "
done #word
done #line
exit 0
