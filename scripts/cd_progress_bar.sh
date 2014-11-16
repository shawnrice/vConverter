#!/bin/bash

DIR=$( cd "$( dirname "$0" )" && pwd )
CD="${DIR}/tools/cocoaDialog.app/Contents/MacOS/cocoaDialog"

ffmpeg="${DIR}/tools/ffmpeg"
sox="${DIR}/tools/sox"

TEMP='/tmp/video_scrubber'

# create a named pipe
rm -f /tmp/hpipe
mkfifo /tmp/hpipe

# create a background job which takes its input from the named pipe
"${CD}" progressbar \
--indeterminate --title "My Program" \
--text "Please wait..." < /tmp/hpipe &

# associate file descriptor 3 with that pipe and send a character through the pipe
exec 3<> /tmp/hpipe
echo -n . >&3

# do all of your work here
sleep 20

# now turn off the progress bar by closing file descriptor 3
exec 3>&-

# wait for all background jobs to exit
wait
rm -f /tmp/hpipe
exit 0

"${ffmpeg}" -i FILE0005.MOV 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,// | sed 's@\..*@@g' | awk '{ split($1, A, ":"); split(A[3], B, "."); print 3600*A[1] + 60*A[2] + B[1] }'


files=$(${CD} fileselect \
--text "Select the videos that you want to combine" \
--with-extensions .swf .avi .srt .vob .mpeg .webm .mkv .wmv .ogv .mts .m2p .mp4 .ts .dv4 .xvid .amc .amx .scm .hdmov .mov .asf .m4v .mpg .avchd .flv .f4p .fli .hdv .mvp .divx .smv .mpeg4 .h264 .aaf .AVCHD .MOV .AVI .MPEG .M4A .MP4 .MKV .MPG \
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



#!/bin/bash
#updated ffmpeg progress indicator
#by Rupert Plumridge
#for updates visit www.prupert.co.uk
#Creative Commons Attribution-Non-Commercial-Share Alike 2.0 UK: England & Wales Licence
# Based on the ffmpegprogress bar from: http://handybashscripts.blogspot.com/2011/01/ffmpeg-with-progress-bar-re-work.html
# which was based on my initital progress script - circle of life and all that ;)
# version 2.0
# 07.04.2011
# now uses apparently better progress detection, based on duration of overall video and progress along the conversion
####################################################################################
# USAGE #
# 1) Run the script with the name of the file to be converted after the name of the script (e.g. ./ffmpeg-progress.sh "My Awesome Video.mpg)
###################################################################################
# Please adjust the following variables as needed.
# It is recommended you at least adjust the first variable, the name of the script
SCRIPT=ffmpeg-progress.sh
LOG=$HOME/ffmpegprog.log

display () # Calculate/collect progress
{
START=$(date +%s); FR_CNT=0; ETA=0; ELAPSED=0
while [ -e /proc/$PID ]; do                         # Is FFmpeg running?
    sleep 2
    VSTATS=$(awk '{gsub(/frame=/, "")}/./{line=$1-1} END{print line}' \
    /tmp/vstats)                                  # Parse vstats file.
    if [ $VSTATS -gt $FR_CNT ]; then                # Parsed sane or no?
        FR_CNT=$VSTATS
        PERCENTAGE=$(( 100 * FR_CNT / TOT_FR ))     # Progbar calc.
        ELAPSED=$(( $(date +%s) - START )); echo $ELAPSED > /tmp/elapsed.value
        ETA=$(date -d @$(awk 'BEGIN{print int(('$ELAPSED' / '$FR_CNT') *\
        ('$TOT_FR' - '$FR_CNT'))}') -u +%H:%M:%S)   # ETA calc.
    fi
    echo -ne "\rFrame:$FR_CNT of $TOT_FR Time:$(date -d @$ELAPSED -u +%H:%M:%S) ETA:$ETA Percent:$PERCENTAGE"                # Text for stats output.

done
}

trap "killall ffmpeg $SCRIPT; rm -f "$RM/vstats*"; exit" \
INT TERM EXIT                                       # Kill & clean if stopped.

# Get duration and PAL/NTSC fps then calculate total frames.
    FPS=$(ffprobe "$1" 2>&1 | sed -n "s/.*, \(.*\) tbr.*/\1/p")
    DUR=$(ffprobe "$1" 2>&1 | sed -n "s/.* Duration: \([^,]*\), .*/\1/p")
    HRS=$(echo $DUR | cut -d":" -f1)
    MIN=$(echo $DUR | cut -d":" -f2)
    SEC=$(echo $DUR | cut -d":" -f3)
    TOT_FR=$(echo "($HRS*3600+$MIN*60+$SEC)*$FPS" | bc | cut -d"." -f1)
    if [ ! "$TOT_FR" -gt "0" ]; then echo error; exit; fi

    # Re-code with it.

    nice -n 15 ffmpeg -deinterlace -vstats_file /tmp/vstats -y -i "$1" -vcodec libx264 -level 41 -vpre main -vpre medium -crf 24 -threads 0 -sn -acodec libfaac -ab 128k -ac 2 -ar 48000 -vsync 1 -async 1000 -map 0.0:0.0 -map 0.1:0.1 "$1".mkv 2>/dev/null &                       # CHANGE THIS FOR YOUR FFMPEG COMMAND.
        PID=$! &&
    echo "ffmpeg PID = $PID"
    echo "Length: $DUR - Frames: $TOT_FR  "
    display                               # Show progress.
        rm -f "$RM"/vstats*                             # Clean up tmp files.

    # Statistics for logfile entry.
    ((BATCH+=$(cat /tmp/elapsed.value)))                # Batch time totaling.
    ELAPSED=$(cat /tmp/elapsed.value)                   # Per file time.
    echo "\nDuration: $DUR - Total frames: $TOT_FR" >> $LOG
    AV_RATE=$(( TOT_FR / ELAPSED ))
    echo -e "Re-coding time taken: $(date -d @$ELAPSED -u +%H:%M:%S)"\
    "at an average rate of $AV_RATE""fps.\n" >> $LOG

exit