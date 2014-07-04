#!/bin/bash

# Perform the following operations on an SRT file
# Convert the file to UTF-8 encoding (and remove any BOM)
# Renumber the entries
# Shift SRT timings by specified delay (in seconds)
# Stretch SRT timings by specified factor (desired/current)

# Requires iconv
# Requires srttool

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

fixSRT()
{
    local details=$(file --brief --mime "${FILE}")
    local filetype=$(echo $details | cut --delimiter=';' --fields=1)
    local encoding=$(echo $details | cut --delimiter='=' --fields=2)

    echo "Filetype: $filetype"
    echo "Encoding: $encoding"

    if [ $filetype != "text/plain" ]
    then
        die 3
    fi
}

main()
{
    parseCommandLineArguments

    fixSRT

    # Output the arguments
    echo "File:     ${FILE}"
    echo "Delay:    ${DELAY} ms"
    echo "Stretch:  ${STRETCH}"
}

main

exit 0

