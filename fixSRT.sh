#!/bin/bash

# Perform the following operations on an SRT file
# Convert the file to UTF-8 encoding (and remove any BOM)
# Renumber the entries
# Shift SRT timings by specified delay (in seconds)
# Stretch SRT timings by specified factor (desired/current)

# Requires iconv
# Requires srttool

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

exit 0

