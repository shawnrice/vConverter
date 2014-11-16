
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