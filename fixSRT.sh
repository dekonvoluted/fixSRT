#!/bin/bash

# Perform the following operations on an SRT file
# Convert the file to UTF-8 encoding (and remove any BOM)
# Renumber the entries
# Shift SRT timings by specified delay (in seconds)
# Stretch SRT timings by specified factor (desired/current)

# Requires iconv
# Requires transcode
# Requires mkvtoolnix

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"

printUsage()
{
    cat <<- EOF
	Usage $PROGNAME [options] FILE.srt

	This script will clean up SRT files by converting the encoding to UTF-8, removing any BOM (byte-order marks) left in the resulting file.
	The entries in the SRT file will also be renumbered in sequential order.

	Optionally, this script can also be used to adjust the delay and fps timings of the SRT file.

	The input file will be moved to FILE.old and the cleaned up file will be written in its place.

	OPTIONS
	-d --delay      Shift all entries by this delay [in milliseconds]
	-s --stretch    Stretch the times by this factor
	-h --help       Print this help message
	EOF
}

die()
{
    case $1 in
        1)
            echo $PROGNAME: ERROR. Unable to parse arguments correctly.;;
        2)
            echo $PROGNAME: ERROR. File not found.;;
        3)
            echo $PROGNAME: ERROR. Unsupported encoding.;;
        4)
            echo $PROGNAME: ERROR. Unable to backup original file.;;
        5)
            echo $PROGNAME: ERROR. Encoding conversion failed.;;
        6)
            echo $PROGNAME: ERROR. Unable to overwrite file.;;
        7)
            echo $PROGNAME: ERROR. Delay adjustment or renumbering failed.;;
        8)
            echo $PROGNAME: ERROR. Stretch failed.;;
        *)
            true;;
    esac
    printUsage
    exit $1
}

parseCommandLineArguments()
{
    # Check for successful parsing of options
    args=$(getopt --name $PROGNAME --options "d:s:h" --longoptions "delay:,stretch:,help" -- ${ARGS})

    [ $? -eq 0 ] || die 1

    eval set -- "${args}"

    # Parse options
    while test $# -gt 0
    do
        case "${1}" in
            -d|--delay)
                local delay=$2
                shift;;
            -s|--stretch)
                local stretch=$2
                shift;;
            -h|--help)
                die 0;;
            --)
                shift
                break;;
            *)
                shift
                berak;;
        esac
        shift
    done

    readonly DELAY="${delay:-0}"
    readonly STRETCH="${stretch:-1.0}"
    readonly FILE=$(realpath ${@})

    # Check if a single, valid file is given
    [ -r "${FILE}" ] || die 2
}

fixEncoding()
{
    local details=$(file --brief --mime "${FILE}")
    local filetype=$(echo $details | cut --delimiter=';' --fields=1)
    local encoding=$(echo $details | cut --delimiter='=' --fields=2)

    [ $filetype == "text/plain" ] || die 3

    cp "${FILE}" "${FILE%.srt}.old" || die 4

    local tmpfile=$(mktemp)

    # Convert encoding to UTF-8
    if [ $encoding != utf-8 ]
    then
        iconv -c --from-code=$encoding --to-code=utf8 "${FILE}" > $tmpfile || die 5
    else
        cat "${FILE}" > $tmpfile
    fi

    # Remove any BOM, if present
    sed --in-place 's/^\xef\xbb\xbf//' $tmpfile

    # Overwrite original file
    mv $tmpfile "${FILE}" || die 6
}

fixDelayAndNumbering()
{
    local tmpfile=$(mktemp)

    local msDelay=$(echo $DELAY 1000 | awk '{printf "%.3f \n", $1/$2}')

    # Renumber the entries
    # Adjust delay if necessary
    srttool -r -d $msDelay -i "${FILE}" > $tmpfile || die 7

    # Overwrite original file
    mv $tmpfile "${FILE}" || die 6
}

fixStretchFactor()
{
    local stretch=$(echo $STRETCH | awk '{printf "%.3f \n", $1}')

    # Check if stretching is necessary
    if [ $stretch == 1.000 ]
    then
        return
    fi

    local tmpfile=$(mktemp)

    # Apply stretch
    mkvmerge --quiet --output $tmpfile --sync 0:0,"${STRETCH}" "${FILE}" || die 8
    mkvextract --quiet tracks $tmpfile 0:"${FILE}" || die 6
    rm -f $tmpfile
}

main()
{
    parseCommandLineArguments

    fixEncoding

    fixDelayAndNumbering

    fixStretchFactor
}

main

exit 0

