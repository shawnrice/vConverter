#!/bin/sh

# This script is __messy__, seriously. But, it seems to work.

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

# Static Variables
# ================

DIR=$( cd "$( dirname "$0" )" && pwd )

ffmpeg="${DIR}/../tools/ffmpeg"
sox="${DIR}/../tools/sox"
mkvmerge="${DIR}/../tools/mkvmerge"

containers="3gp 3g2 asf wma wmv avi divx evo f4v flv mk3d mka mks mcf mp4 mpg mpeg m2p ps ts m2ts mxf ogg mov qt rmvb webm 3GP 3G2 ASF WMA WMV AVI DIVX EVO F4V FLV MK3D MKA MKS MCF MP4 MPG MPEG M2P PS TS M2TS MXF OGG MOV QT RMVB WEBM"

TEMP='/tmp/video_scrubber'
[[ ! -d "${TEMP}" ]] && mkdir "${TEMP}"

# Temporary Variables
# ===================
file=
lighten=0
replace=0
reduce_noise=0

# Functions
# =========

# Usage info
# ==========
show_help() {
cat << EOF
Usage: ${0##*/} [-r] [-l] [--size SIZE] [--output "/PATH/TO/OUTPUT/FILE"] [--files "/PATH/TO/FILE1 /PATH/TO/FILE2"]
Combines, resizes, lightens, and reduces background noise of video files. Outputs an .mp4 file.

    Required
    ========
    -o, --output    the output file
        ex. --output "/full/path/to/file.mp4"

    -f, --files     the input file(s)
        ex. --files="/full/path/to/file1.mov,/full/path/to/file2"

    -s, --size      the size preset must be one of 'tiny' 'small' 'medium' 'large'
        ex. --size tiny

    Optional
    ========
    -l              ligthen the video
    -r              reduce audio background noise
    -h, --help      display this help and exit

EOF
}


function check_for_container() {
    # $1 is the extension
    [[ $1 == *"${containers}"* ]] && echo "true" && return 0
    echo "false" && return 1
}

function combine_videos() {
    # It's easier to use mkv files here
    first=1
    cmd="\"${mkvmerge}\" -o \"${TEMP}/combined.mkv\""
    IFS=$'\n'
    for file in $(ls "${TEMP}/converted"); do
        file=$(echo "${file}" | sed 's| ||g')
        if [[ 1 -eq $first ]]; then
            cmd="${cmd} \"${TEMP}/converted/${file}\""
            first=0
        else
            cmd="${cmd} + \"${TEMP}/converted/${file}\""
        fi
    done
    eval $cmd
}

function alter_size() {
    # Use an mp4 to an mp4
    file="$1"
    number="$3"

    local extension="${file##*.}"
    local name=$(basename "${file}")
    local name="${name%.*}"

    [[ ! -d "${TEMP}/altered" ]] && mkdir "${TEMP}/altered"

    cmd="avconvert -q -prog -p \"${preset}\" -s \"${file}\" -o \"${TEMP}/altered/${name}.${extension}\" 2>&1 | grep \"progress\""
    eval $cmd
}

function convert_to_mp4() {
    # Use an mkv to get an mp4
    local file="$1"
    local target="$2"

    if [[ 1 -eq $lighten ]]; then
        eval "\"${ffmpeg}\" -loglevel panic -stats -y -i \"${file}\" -acodec copy -vcodec copy -strict -2 \"${target}\""
    else
        eval "\"${ffmpeg}\" -loglevel panic -stats -y -i \"${file}\" -acodec libvo_aacenc -vcodec copy -strict -2 \"${target}\""
    fi

}

function convert_to_mkv() {
    # Use anything that has a container
    file="$1"
    number="$2"
    local extension="${file##*.}"
    local name=$(basename "${file}")
    local name="${name%.*}"

    alter_size "${file}" "${preset}" $number

    if [[ 1 -eq $reduce_noise ]]; then
        "${DIR}/scrub-audio.sh" "${TEMP}/altered/${name}.${extension}" "${TEMP}/altered/${name}.${extension}"
    fi
    if [[ 1 -eq $lighten ]]; then
        "${DIR}/lighten-video.sh" "${TEMP}/altered/${name}.${extension}" "${TEMP}/altered/${name}.${extension}"
    fi

    [[ ! -d "${TEMP}/converted" ]] && mkdir "${TEMP}/converted"
    "${mkvmerge}" -q -o "${TEMP}/converted/f__${number}__${name}.mkv" "${TEMP}/altered/${name}.${extension}" > /dev/null

}

function realpath() {
    echo $(cd $(dirname $1); pwd)/$(basename $1)
}

# Parse Options
# =============

while :; do
    case $1 in
        -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
            show_help
            exit
            ;;
        -s|--size)       # Takes an option argument, ensuring it has been specified.
            if [ "$2" ]; then
                    preset=$2
                    shift 2
                continue
            else
                echo "ERROR: You must specify a size '--size (tiny|small|medium|large)'." >&2
                exit 1
            fi
            ;;
        --size=?*)
            preset=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --size=)         # Handle the case of an empty --size=
                echo "ERROR: You must specify a size '--size (tiny|small|medium|large)'." >&2
            exit 1
            ;;

        -o|--output)       # Takes an option argument, ensuring it has been specified.
            if [ "$2" ]; then
                    target="$2"
                    shift 2
                continue
            else
                echo "ERROR: You must specify an output file '--output \"/full/path/to/file\"'." >&2
                exit 1
            fi
            ;;
        --output=?*)
            target=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --output=)         # Handle the case of an empty --output=
            echo "ERROR: You must specify an output file '--output \"/full/path/to/file\"'." >&2
            exit 1
            ;;


        -f|--files)       # Takes an option argument, ensuring it has been specified.
            if [ "$2" ]; then
                    files="$2"
                    shift 2
                continue
            else
                echo "ERROR: You must specify at least one input file '--files \"/full/path/to/file," \
                     "/full/path/to/file2\"'." >&2
                exit 1
            fi
            ;;
        --files=?*)
            files=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --files=)         # Handle the case of an empty --files=
            echo "ERROR: You must specify at least one input file '--files \"/full/path/to/file," \
                 "/full/path/to/file2\"'." >&2
            exit 1
            ;;
        -l|--lighten)
            lighten=1 # Each -v argument adds 1 to verbosity.
            ;;
        -p|--place)
            replace=1 # Each -v argument adds 1 to verbosity.
            ;;
        -r|--reduce-noise)
            reduce_noise=1 # Each -v argument adds 1 to verbosity.
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

#  --file is a required option. Check that it has been set.
if [ ! "${files}" ]; then
    echo 'ERROR: required argument --files="FILE,FILE2" not given. See --help.' >&2
    exit 1
fi
if [ ! "${target}" ]; then
    echo 'ERROR: required argument --output "/full/path/to/file.mp4" not given. See --help.' >&2
    exit 1
fi

presets="tiny small medium large"
if [[ ! $presets == *$preset* ]] || [ -z $preset ]; then
    echo "ERROR: You must specify a valid size '--size (tiny|small|medium|large)'." >&2
    exit 1
fi


tiny='PresetAppleM4ViPod'
small='PresetAppleM4V480pSD'
medium='PresetAppleM4VAppleTV'
large='PresetAppleM4V720pHD'

preset=$(eval echo \$$preset)

#     # Order of Operations
#     # ===================
#     # 01 - check for # of files (or just one)
#     # 02 - check for contianers
#     # 06 - resize file to preset
#     # 03 - convert files (if necessary)
#     # 04 - combine files (if necessary)
#     # 05 - convert to mp4
#     # 07 - scrub audio (if necessary)  *external script
#     # 08 - lighten file (if necessary) *external script
#     # 09 - return new file
#     # 10 - clean up

files=$(echo $files | sed 's|"||g' )

(
    count=0
    IFS=','
    for f in ${files}; do
        convert_to_mkv "${f}" $count
        count=$((count + 1))
    done

)

combine_videos 2>&1 > /dev/null
convert_to_mp4 "${TEMP}/combined.mkv" "${TEMP}/combined.mp4"

target=$(echo $target | sed "s|'||g")

echo "Moving ${TEMP}/combined.mp4 to ${target}"
mv "${TEMP}/combined.mp4" "${target}"
rm -fR "${TEMP}"