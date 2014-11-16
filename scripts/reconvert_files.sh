#!/bin/bash

# Variables
# =========

DIR=$( cd "$( dirname "$0" )" && pwd )

ffmpeg="${DIR}/tools/ffmpeg"
sox="${DIR}/tools/sox"
mkvmerge="${DIR}/tools/mkvmerge"

containers="3gp 3g2 asf wma wmv avi divx evo f4v flv mk3d mka mks mcf mp4 mpg mpeg m2p ps ts m2ts mxf ogg mov qt rmvb webm 3GP 3G2 ASF WMA WMV AVI DIVX EVO F4V FLV MK3D MKA MKS MCF MP4 MPG MPEG M2P PS TS M2TS MXF OGG MOV QT RMVB WEBM"

TEMP='/tmp/video_scrubber'
[[ ! -d "${TEMP}" ]] && mkdir "${TEMP}"


# Order of Operations
# ===================
# 01 - check for # of files (or just one)
# 02 - check for contianers
# 03 - convert files (if necessary)
# 04 - combine files (if necessary)
# 05 - convert to mp4
# 06 - resize file to preset
# 07 - scrub audio (if necessary)  *external script
# 08 - lighten file (if necessary) *external script
# 09 - return new file
# 10 - clean up

# Don't forget ---
# ============
# Locks
# Traps
# Clean-up

# Functions
# =========

function check_for_container() {
    # $1 is the extension
    [[ $1 == *"${containers}"* ]] && echo "true" && return 0
    echo "false" && return 1
}

function combine_videos() {
    # It's easier to use mkv files here
    first=1
    cmd="\"${mkvmerge}\" -o \"${TEMP}/combined.mkv"
    for file in $(ls "${TEMP}/combine"); do
        if [[ $first -eq 1 ]]; then
            cmd="${cmd} \"${file}\""
        else
            cmd="${cmd} + \"${file}\""
        fi
    done
    $cmd
}

function alter_size() {
    # Use an mp4 to an mp4
    file="$1"
    choice="$2"

    tiny='PresetAppleM4ViPod'
    small='PresetAppleM4V480pSD'
    medium='PresetAppleM4VAppleTV'
    large='PresetAppleM4V720pHD'

    preset=$(eval \$$choice)
    avconvert -q -prog -p "${preset}" -s "${file}" -o /Users/Sven/Desktop/FILE0002-480pSD.MOV | grep "progress"
}

function convert_to_mp4() {
    # Use an mkv to get an mp4
    file="$1"
    target="$2"

    "${ffmpeg}" -i "${file}" -acodec copy -vcodec copy "${target}"
}

function convert_to_mkv() {
    # Use anything that has a container
    file="$1"
    number="$2"
    local extension="${file##*.}"
    local name="${file%.*}"

    [[ ! -d "${TEMP}/combine" ]] && mkdir "${TEMP}/combine"
    "${mkvmerge}" -o "${TEMP}/combine/file${number}.mkv" "${file}"
}

function realpath() {
    echo $(cd $(dirname $1); pwd)/$(basename $1)
}

# Code
# ====

if [[ 0 == $# ]]; then
    echo "You need to provide some arguments."
    exit 1
fi

files=()
for file in $@; do
    if [ ! -f $(realpath "${file}") ]; then
        echo "ERROR: ${file} does not exist."
        exit 1
    fi
    files+="'${file}',"
done
echo $files