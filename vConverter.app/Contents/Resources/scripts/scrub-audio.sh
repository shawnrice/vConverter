#!/bin/bash

# Variables
# =========

DIR=$( cd "$( dirname "$0" )" && pwd )
sox="${DIR}/../tools/sox"
ffmpeg="${DIR}/../tools/ffmpeg"

TEMP='/tmp/video_scrubber'
[[ ! -d "${TEMP}" ]] && mkdir "${TEMP}"

function scrub_audio() {
    # Use an mp4
    file="$1"
    output="$2"
    local noise="${DIR}/../assets/noise.prof"
    local noise_sample_mov="${DIR}/../assets/noise_sample.mov"
    local noise_sample="${DIR}/../assets/noiseaud.wav"
    local extension=$(echo "${file##*.}" | tr [A-Z] [a-z])
    local name=$(basename ${file})
    local name="${name%.*}"
    local temp=$(echo ${file} | openssl enc -base64)"-noisered"

    touch "${TEMP}/${temp}.lock"
    [[ ! -d "${TEMP}/${temp}" ]] && mkdir "${TEMP}/${temp}"

    "${ffmpeg}" -loglevel panic -stats -y -i "${file}" -c copy -an "${TEMP}/${temp}/tmp.${extension}"
    "${ffmpeg}" -loglevel panic -stats -y -i "${file}" "${TEMP}/${temp}/tmp.wav"
    "${ffmpeg}" -loglevel panic -stats -y -i "${noise_sample_mov}" -vn -ss 00:00:00 -t 00:00:01 "${TEMP}/${temp}/noiseaud.wav"
    "${sox}" "${TEMP}/${temp}/noiseaud.wav" -n noiseprof "${TEMP}/${temp}/noise.prof"
    "${sox}" "${TEMP}/${temp}/tmp.wav" "${TEMP}/${temp}/tmp-clean.wav" noisered "${TEMP}/${temp}/noise.prof" 0.21
    "${ffmpeg}" -loglevel panic -stats -y -i "${TEMP}/${temp}/tmp-clean.wav" -i "${TEMP}/${temp}/tmp.${extension}" -c copy -strict -2 "${TEMP}/${temp}/${name}-scrubbed.${extension}"
    mv "${TEMP}/${temp}/${name}-scrubbed.${extension}" "${output}"
    rm -fR "${TEMP}/${temp}"
    rm "${TEMP}/${temp}.lock"
}

if [[ ! -f "$1" ]]; then
    echo "ERROR: '$1' is does not exist."
    exit 1
fi

scrub_audio "$1" "$2"