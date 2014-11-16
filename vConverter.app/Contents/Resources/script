#!/bin/bash


if [[ 0 -eq $# ]]; then
    echo "Please drop some video files on this textbox to process them."
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "About to process:"
echo "================="
for f in $@; do
    echo $f
done
echo " "
echo "Please set the options..."
echo "This might take a little while. Go get some coffee."
sleep 1
"${DIR}/scripts/pashua.sh" $@

file="${DIR}/assets/video-256.png"
file=$(echo $file | tr '/' ':')
file=$(echo "${file:1:${#file}-1}")

osascript -e "display dialog \"Video conversion done.\" with title \"vConverter\" with icon file \"${file}\""

cat << EOF



















                                ============
                                    DONE
                                ============










EOF