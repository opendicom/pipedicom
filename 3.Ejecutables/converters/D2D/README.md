# D2D

DICOM binary to DICOM binary with compresión and coerción inbetween

## args
D2D D2DspoolDirPath D2DsuccessDir D2DfailureDir D2DdoneDir

## Environment
- "D2DcompressJ2K" convierte explicit little endian a jpeg 2000 lossless with quality layers separated into tile-parts.
- "D2DjsonDataset" attributes overriding the originals

## stderr
logging

## stdout
0=success
