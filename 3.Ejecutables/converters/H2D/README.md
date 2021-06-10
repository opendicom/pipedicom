# H2D

hexa (H) is a codification of binary DICOM available in dcm_attrs blobs of dcm4chee mysql databases.

It is very inefficient but remains complete in a string type answer to a command line query to mysql. In Mysql 5.6, we experienced problems with the alternative base64 codification. This is the reason why we use hexa.

This executable is normally piped to D2J

## options
none

## Environment
none

## stdin
dataset codified in hexa

## stderr
Logging

## stdout
dataset in binary dicom 
