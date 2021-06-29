# DCKV

Library used by DinlineJ, DsourceJ, D2, D2D and J2D
Includes openjpeg library and dependencies.

## instalation
/usr/local/lib/DCKV.framework
/usr/local/lib/libopenjp2.2.5.0.dylib
/usr/local/lib/libopenjp2.7.dylib -> libopenjp2.2.5.0.dylib

## not installed yet

third party libs for libopenjpg2:
- liblcms2.a
- libopenjp2.a
- libpng.a
- libtiff.a
- libz.a

executable:
- opj_compress
- opj_dump
- opj_decompress

Nota:
opj_compress should be copied in the executable folder where D2 or D2D are installed


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
