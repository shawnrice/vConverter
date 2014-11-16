#!/bin/bash

# Variables
# =========

DIR=$( cd "$( dirname "$0" )" && pwd )
ffmpeg="${DIR}/../tools/ffmpeg"

TEMP='/tmp/video_scrubber'
[[ ! -d "${TEMP}" ]] && mkdir "${TEMP}"

function lighten_video() {
    input="$1"
    output="$2"

    local extension=$(echo "${input##*.}" | tr [A-Z] [a-z])
    local name=$(basename ${input})
    local name="${name%.*}"
    local temp=$(echo ${input} | openssl enc -base64)"-lighten"

    [[ ! -d "${TEMP}/${temp}" ]] && mkdir "${TEMP}/${temp}"

    "${ffmpeg}" -loglevel panic -stats -y -i "${input}" -vf mp=eq2=1.3:1:0.1:1.15:1:1.3:1.55:0 -strict -2 "${TEMP}/${temp}/${name}.${extension}"
    mv "${TEMP}/${temp}/${name}.${extension}" "${output}"
    rm -fR "${TEMP}/${temp}"
}

if [[ ! -f "$1" ]]; then
    echo "ERROR: '$1' is does not exist."
    exit 1
fi

if [[ ! -d "$(dirname $2)" ]]; then
    echo "ERROR: $(dirname $2) does not exist."
    exit 1
fi

lighten_video "$1" "$2"