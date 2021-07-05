# DCKV

Library used by DinlineJ, DsourceJ, D2, D2D and J2D
Includes openjpeg library and dependencies.

## install

Write the current admin user password in the echo line of installerPassword.sh
This allows to sudo the instalation of openjpeg and dckv in /usr/local

## /Library/Frameworks
- DCKV.framework

## /usr/local/lib
- libopenjp2.2.5.0.dylib
- libopenjp2.7.dylib -> libopenjp2.2.5.0.dylib
- liblcms2.a
- libopenjp2.a
- libpng.a
- libtiff.a
- libz.a

## /usr/local/bin
- opj_compress
- opj_dump
- opj_decompress

we add these symlink fo facilitate stdin and stdout instead of filenames when using opj_compress
ln -s /dev/stdin stdin.rawl
ln -s /dev/stdout stdout.j2k


## <DCKV/DCKV.h>

<DCKV/DCMcharset.h>
<DCKV/D2dict.h>
<DCKV/dict2D.h>
<DCKV/dckRangeVecs.h>
<DCKV/ODLog.h>
<DCKV/B64.h>
<DCKV/NSData+MD5.h>
<DCKV/NSData+DCMmarkers.h>
<DCKV/j2k.h>


## XML resources

### Native format
N.xsd (definition)
N.rng (definition)
N1M.xsl  (conversion xslt1 to map DCKV format)

### DCKV format
M.xsd (definition)
M1N.xsl (conversion xslt1 to native format)

### xslt 3 equivalence XML - JSON
schema-for-json.xsd (definition)
M3J.xsl (conversion xslt3 of DCKV to JSON)
