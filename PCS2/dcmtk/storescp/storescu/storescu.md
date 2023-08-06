## DCMTK 3.6.6

# storescp: DICOM storage (C-STORE) SCU

## SYNOPSIS

storescu [options] peer port dcmfile-in...

## DESCRIPTION

The storescu application implements a Service Class User (SCU) for the Storage Service Class. For each DICOM file on the command line it sends a C-STORE message to a Storage Service Class Provider (SCP) and waits for a response. The application can be used to transmit DICOM images and other DICOM composite objects.

## PARAMETERS

peer        hostname of DICOM peer

port        tcp/ip port number of peer

dcmfile-in  DICOM file or directory to be transmitted

## OPTIONS

general options

  -h    --help
          print this help text and exit

        --version
          print version information and exit
    
        --arguments
          print expanded command line arguments

  -q    --quiet
          quiet mode, print no warnings and errors

  -v    --verbose
          verbose mode, print processing details

  -d    --debug
          debug mode, print debug information

  -ll   --log-level  [l]evel: string constant
          (fatal, error, warn, info, debug, trace)
          use level l for the logger

  -lc   --log-config  [f]ilename: string
          use config file f for the logger

  +v    --verbose-pc
          show presentation contexts in verbose mode

input options

input file format:

  +f    --read-file
          read file format or data set (default)

  +fo   --read-file-only
          read file format only

  -f    --read-dataset
          read data set without file meta information

input files:

  +sd   --scan-directories
          scan directories for input files (dcmfile-in)

  +sp   --scan-pattern  [p]attern: string (only with --scan-directories)
          pattern for filename matching (wildcards)

          # possibly not available on all systems

  -r    --no-recurse
          do not recurse within directories (default)

  +r    --recurse
          recurse within specified directories

  -rn   --no-rename
          do not rename processed files (default)

  +rn   --rename
          append .done/.bad to processed files

network options

application entity titles:

  -aet  --aetitle  [a]etitle: string
          set my calling AE title (default: STORESCU)

  -aec  --call  [a]etitle: string
          set called AE title of peer (default: ANY-SCP)

association negotiation profile from configuration file:

  -xf   --config-file  [f]ilename, [p]rofile: string
          use profile p from config file f

proposed transmission transfer syntaxes (not with --config-file):

  -x=   --propose-uncompr
          propose all uncompressed TS, explicit VR
          with local byte ordering first (default)

  -xe   --propose-little
          propose all uncompressed TS, explicit VR little endian first

  -xb   --propose-big
          propose all uncompressed TS, explicit VR big endian first

  -xi   --propose-implicit
          propose implicit VR little endian TS only

  -xs   --propose-lossless
          propose default JPEG lossless TS
          and all uncompressed transfer syntaxes

  -xy   --propose-jpeg8
          propose default JPEG lossy TS for 8 bit data
          and all uncompressed transfer syntaxes

  -xx   --propose-jpeg12
          propose default JPEG lossy TS for 12 bit data
          and all uncompressed transfer syntaxes

  -xv   --propose-j2k-lossless
          propose JPEG 2000 lossless TS
          and all uncompressed transfer syntaxes

  -xw   --propose-j2k-lossy
          propose JPEG 2000 lossy TS
          and all uncompressed transfer syntaxes

  -xt   --propose-jls-lossless
          propose JPEG-LS lossless TS
          and all uncompressed transfer syntaxes

  -xu   --propose-jls-lossy
          propose JPEG-LS lossy TS
          and all uncompressed transfer syntaxes

  -xm   --propose-mpeg2
          propose MPEG2 Main Profile @ Main Level TS only

  -xh   --propose-mpeg2-high
          propose MPEG2 Main Profile @ High Level TS only

  -xn   --propose-mpeg4
          propose MPEG4 AVC/H.264 High Profile / Level 4.1 TS only

  -xl   --propose-mpeg4-bd
          propose MPEG4 AVC/H.264 BD-compatible HP / Level 4.1 TS only

  -x2   --propose-mpeg4-2-2d
          propose MPEG4 AVC/H.264 HP / Level 4.2 TS for 2D Videos only

  -x3   --propose-mpeg4-2-3d
          propose MPEG4 AVC/H.264 HP / Level 4.2 TS for 3D Videos only

  -xo   --propose-mpeg4-2-st
          propose MPEG4 AVC/H.264 Stereo HP / Level 4.2 TS only

  -x4   --propose-hevc
          propose HEVC H.265 Main Profile / Level 5.1 TS only

  -x5   --propose-hevc10
          propose HEVC H.265 Main 10 Profile / Level 5.1 TS only

  -xr   --propose-rle
          propose RLE lossless TS
          and all uncompressed transfer syntaxes

  -xd   --propose-deflated
          propose deflated explicit VR little endian TS
          and all uncompressed transfer syntaxes

  -R    --required
          propose only required presentation contexts
          (default: propose all supported)

          # This will also work with storage SOP classes that are
          # supported by DCMTK but are not in the list of SOP classes
          # proposed by default.

  +C    --combine
          combine proposed transfer syntaxes
          (default: separate presentation context for each TS)

post-1993 value representations:

  +u    --enable-new-vr
          enable support for new VRs (UN/UT) (default)

  -u    --disable-new-vr
          disable support for new VRs, convert to OB

deflate compression level (only with --propose-deflated or --config-file):

  +cl   --compression-level  [l]evel: integer (default: 6)
          0=uncompressed, 1=fastest, 9=best compression

user identity negotiation:

  -usr  --user  [u]ser name: string
          authenticate using user name u

  -pwd  --password  [p]assword: string (only with --user)
          authenticate using password p

  -epw  --empty-password
          send empty password (only with --user)

  -kt   --kerberos  [f]ilename: string
          read kerberos ticket from file f

        --saml  [f]ilename: string
          read SAML request from file f
    
        --jwt  [f]ilename: string
          read JWT data from file f

  -rsp  --pos-response
          expect positive response

other network options:

  -to   --timeout  [s]econds: integer (default: unlimited)
          timeout for connection requests

  -ts   --socket-timeout  [s]econds: integer (default: 60)
          timeout for network socket (0 for none)

  -ta   --acse-timeout  [s]econds: integer (default: 30)
          timeout for ACSE messages

  -td   --dimse-timeout  [s]econds: integer (default: unlimited)
          timeout for DIMSE messages

  -pdu  --max-pdu  [n]umber of bytes: integer (4096..131072)
          set max receive pdu to n bytes (default: 16384)

        --max-send-pdu  [n]umber of bytes: integer (4096..131072)
          restrict max send pdu to n bytes
    
        --repeat  [n]umber: integer
          repeat n times
    
        --abort
          abort association instead of releasing it

  -nh   --no-halt
          do not halt if unsuccessful store encountered
          (default: do halt)

  -up   --uid-padding
          silently correct space-padded UIDs

  +II   --invent-instance
          invent a new SOP instance UID for every image sent

  +IR   --invent-series  [n]umber: integer (implies --invent-instance)
          invent a new series UID after n images have been sent
          (default: 100)

  +IS   --invent-study  [n]umber: integer (implies --invent-instance)
          invent a new study UID after n series have been sent
          (default: 50)

  +IP   --invent-patient  [n]umber: integer (implies --invent-instance)
          invent a new patient ID and name after n studies have been sent
          (default: 25)

transport layer security (TLS) options

transport protocol stack:

  -tls  --disable-tls
          use normal TCP/IP connection (default)

  +tls  --enable-tls  [p]rivate key file, [c]ertificate file: string
          use authenticated secure TLS connection

  +tla  --anonymous-tls
          use secure TLS connection without certificate

private key password (only with --enable-tls):

  +ps   --std-passwd
          prompt user to type password on stdin (default)

  +pw   --use-passwd  [p]assword: string
          use specified password

  -pw   --null-passwd
          use empty string as password

key and certificate file format:

  -pem  --pem-keys
          read keys and certificates as PEM file (default)

  -der  --der-keys
          read keys and certificates as DER file

certification authority:

  +cf   --add-cert-file  [f]ilename: string
          add certificate file to list of certificates

  +cd   --add-cert-dir  [d]irectory: string
          add certificates in d to list of certificates

security profile:

  +px   --profile-bcp195
          BCP 195 TLS Profile (default)

  +py   --profile-bcp195-nd
          Non-downgrading BCP 195 TLS Profile

  +pz   --profile-bcp195-ex
          Extended BCP 195 TLS Profile

  +pb   --profile-basic
          Basic TLS Secure Transport Connection Profile (retired)

  +pa   --profile-aes
          AES TLS Secure Transport Connection Profile (retired)

  +pn   --profile-null
          Authenticated unencrypted communication
          (retired, was used in IHE ATNA)

ciphersuite:

  +cc   --list-ciphers
          show list of supported TLS ciphersuites and exit

  +cs   --cipher  [c]iphersuite name: string
          add ciphersuite to list of negotiated suites

pseudo random generator:

  +rs   --seed  [f]ilename: string
          seed random generator with contents of f

  +ws   --write-seed
          write back modified seed (only with --seed)

  +wf   --write-seed-file  [f]ilename: string (only with --seed)
          write modified seed to file f

peer authentication:

  -rc   --require-peer-cert
          verify peer certificate, fail if absent (default)

  -ic   --ignore-peer-cert
          don't verify peer certificate

## NOTES

Scanning Directories

Adding directories as a parameter to the command line only makes sense if option –scan-directories is also given. If the files in the provided directories should be selected according to a specific name pattern (e.g. using wildcard matching), option –scan-pattern has to be used. Please note that this file pattern only applies to the files within the scanned directories, and, if any other patterns are specified on the command line outside the –scan-pattern option (e.g. in order to select further files), these do not apply to the specified directories.