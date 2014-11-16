#!/bin/bash

DIR=$( cd "$( dirname "$0" )" && pwd )
CD="${DIR}/tools/cocoaDialog.app/Contents/MacOS/cocoaDialog"

### Example 1
files=$(${CD} fileselect \
--text "Select the videos that you want to combine" \
--with-extensions .swf .avi .srt .vob .mpeg .webm .mkv .wmv .ogv .mts .m2p .mp4 .ts .dv4 .xvid .amc .amx .scm .hdmov .mov .asf .m4v .mpg .avchd .flv .f4p .fli .hdv .mvp .divx .smv .mpeg4 .h264 .aaf .MOV .AVI .MPEG .M4A .MP4 .MKV .MPG \
    --select-multiple \
    --with-directory ${HOME}/Desktop
    )

if [ -n "${files}" ]; then
    ### Loop over lines returned by fileselect
    echo -e "${files}" | while read file; do
        if [ -e "${file}" ]; then
            echo "${file}"
            extension="${file##*.}"
        fi
    done
    else
        echo "No files chosen"
fi