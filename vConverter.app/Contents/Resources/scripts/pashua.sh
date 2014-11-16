#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pashuapath="${MYDIR}/../tools/Pashua.app/Contents/MacOS/Pashua"

function realpath() {
    echo $(cd $(dirname $1); pwd)/$(basename $1)
}


files=''
for f in $@; do
  f="$(realpath ${f})"
  if [ $f != "/Users"* ]; then
    files="${files}${f}[return]"
  else
    files="${files}${f}"
  fi
done

# Include pashua.sh to be able to use the 2 functions defined in that file
# Function for communicating with Pashua
#
# Argument 1: Configuration string
# Argument 2: Path to a folder containing Pashua.app (optional)
pashua_run() {
    # Write config file
    local pashua_configfile=`/usr/bin/mktemp /tmp/pashua_XXXXXXXXX`
    echo "$1" > $pashua_configfile

    # pashuapath="${MYDIR}/tools/Pashua.app/Contents/MacOS/Pashua"

    if [ "" = "$pashuapath" ]
    then
        >&2 echo "Error: Pashua could not be found"
        exit 1
    fi

    # Get result
    local result=$("$pashuapath" $pashua_configfile | perl -pe 's/ /;;;/g;')

    # Remove config file
    rm $pashua_configfile

    # echo "Results: ${result}"
    # Parse result
    for line in $result
    do
        key=$(echo $line | sed 's/^\([^=]*\)=.*$/\1/')
        value=$(echo $line | sed 's/^[^=]*=\(.*\)$/\1/' | sed 's/;;;/ /g')
        varname=$key
        varvalue="$value"
        eval $varname='$varvalue'
    done
}

# Define the dialog

conf="
*.title = Video Scrubber Options
"

conf="$conf
  img.type = image
  img.x = 12
  img.y = 192
  img.maxwidth = 96
  img.path = ${MYDIR}/../assets/video-256.png

  # Introductory text
  txt.type = text
  txt.default = Files to combine:[return]${files}[return]Please set the options.
  txt.height = 0
  txt.width = 340
  txt.x = 144
  txt.y = 192

  # Save File
  svb.type = savebrowser
  svb.label = Please set the destination path
  svb.default = ${HOME}/Desktop/output.mp4
  svb.filetype = mp4
  svb.width = 460
  svb.x = 0
  svb.y = 124

  # Add the sizing presets
  pop.type = popup
  pop.label = Select Size Preset:
  pop.width = 192
  pop.option = Tiny (Recommended)
  pop.option = Small
  pop.option = Medium
  pop.option = Large
  pop.default = Tiny (Recommended)
  pop.tooltip = Reducing the size reduces the file size, making uploads faster.
  pop.x = 0
  pop.y = 72

  reduce_noise.rely = -18
  reduce_noise.type = checkbox
  reduce_noise.label = Reduce Background Noise
  reduce_noise.tooltip = Reduces background noise from projectors and air conditioning.
  reduce_noise.default = 1
  reduce_noise.x = 0
  reduce_noise.y = 48

  lighten.rely = -18
  lighten.type = checkbox
  lighten.label = Lighten Video
  lighten.tooltip = Good for darker recordings, takes longer to convert.
  lighten.default = 0
  lighten.x = 180
  lighten.y = 48

  # overwrite.rely = -18
  # overwrite.type = checkbox
  # overwrite.label = Overwrite Existing File
  # overwrite.tooltip = This is an element of type “checkbox”
  # overwrite.default = 0
  # overwrite.x = 285
  # overwrite.y = 48

  # Add a cancel button with default label
  cb.type = cancelbutton
"

pashua_run "$conf" "$customLocation"

files='--files="'
for f in $@; do
  f="$(realpath ${f})"
  if [ $f != "/Users"* ]; then
    files="${files}${f},"
  else
    files=$files$f
  fi
done
files=${files%?}'"'

pop=$(echo ${pop% *} | tr [A-Z] [a-z])
cmd="\"${MYDIR}/opts.sh\""
[[ 1 -eq $reduce_noise ]] && cmd="${cmd} --reduce-noise "
[[ 1 -eq $lighten ]] && cmd="${cmd} --lighten "
[[ 1 -eq $overwrite ]] && cmd="${cmd} --place "
cmd="${cmd} ${files}"
cmd="${cmd} --output '${svb}'"
cmd="${cmd} --size ${pop} "

eval "$cmd"

exit

