#!/usr/bin/env bash

#  stdin | b64uid | stdout
#
#  Created by jacquesfauquex on 2022-08-25.
#

declare -A b64=( [-]=0x00 [0]=0x01 [1]=0x02 [2]=0x03 [3]=0x04 [4]=0x05 [5]=0x06 [6]=0x07 [7]=0x08 [8]=0x09 [9]=0x0A [A]=0x0B [B]=0x0C [C]=0x0D [D]=0x0E [E]=0x0F [F]=0x10 [G]=0x11 [H]=0x12 [I]=0x13 [J]=0x14 [K]=0x15 [L]=0x16 [M]=0x17 [N]=0x18 [O]=0x19 [P]=0x1A [Q]=0x1B [R]=0x1C [S]=0x1D [T]=0x1E [U]=0x1F [V]=0x20 [W]=0x21 [X]=0x22 [Y]=0x23 [Z]=0x24 [_]=0x25 [a]=0x26 [b]=0x27 [c]=0x28 [d]=0x29 [e]=0x2A [f]=0x2B [g]=0x2C [h]=0x2D [i]=0x2E [j]=0x2F [k]=0x30 [l]=0x31 [m]=0x32 [n]=0x33 [o]=0x34 [p]=0x35 [q]=0x36 [r]=0x37 [s]=0x38 [t]=0x39 [u]=0x3A [v]=0x3B [w]=0x3C [x]=0x3D [y]=0x3E [z]=0x3F )

hb2char=( 1.2.840.10008. . 0. 0 1. 1 2. 2 3. 3 4 5 6 7 8 9 )
separators=( /studies/ /series/ /instances/ )
function b642hb {
    #$1 b64 word
    #echo '<'"$1"'>'
    [[ ${#1} -gt 48 ]] && exit -1 #is aproximate (because of x. optimizations)

    let "b64Count=${#1}-2"
    for (( j=0; j<$b64Count; j+=2 ))
    do
      # "00aaaabb""00bbcccc"
      echo -n "${hb2char[ $(( ${b64[${1:$j:1}]} >> 2 )) ]}"
      echo -n "${hb2char[ $(( (( ${b64[${1:$j:1}]} & 0x03) << 2)+( ${b64[${1:$j+1:1}]} >> 4) )) ]}"
      echo -n "${hb2char[ $(( ${b64[${1:$j+1:1}]} & 0x0F )) ]}"
    done
    echo -n ${hb2char[ $(( ${b64[${1:$j:1}]} >> 2 )) ]}
    b="${hb2char[ $(( (( ${b64[${1:$j:1}]} & 0x03) << 2)+( ${b64[${1:$j+1:1}]} >> 4) )) ]}"
    c="${hb2char[ $(( ${b64[${1:$j+1:1}]} & 0x0F )) ]}"
    if [[ $c == . ]];then
      if [[ $b != . ]];then
        echo -n $b
      fi
    else
      echo -n $b$c
    fi
}


while read line; do
for word in $line; do
echo 'word:<'"$word"'>'
   slashCount=0
   while [[ ${#word} -gt 0 ]];do
      beforeSlash="${word%%/*}"
      [[ "$beforeSlash" != '' ]] && b642hb $beforeSlash
      if [[ $word == $beforeSlash ]];then
         word=''
      else
         word=${word#*/}
         echo -n "${separators[$slashCount]}"
         slashCount=$(( slashCount+=1 ))
      fi
   done
   echo ''
done #word
done #line
exit 0
