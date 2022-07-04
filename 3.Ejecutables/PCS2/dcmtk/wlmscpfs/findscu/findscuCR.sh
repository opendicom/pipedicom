#!/bin/sh
/usr/local/bin/findscu -d -aec DCM4CHEE -W -k "(0040,0100)[0].Modality=CR" -k "(0010,0010)" -k "(0010,0020)" +sr -od /Users/Shared/dcmtk/wlmscpfs -Xs findscuCRresp.xml localhost $1
