#/bin/bash

set -e
OUTDIR=$(pwd)
BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR

# show shell which runs this script
# echo "$(ps h -p $$ -o args='' | cut -f1 -d' ')"

usage() {
    echo "Usage: $0 [OPTIONS] URL"
    echo ""
    echo "Uses yt-dlp to download and convert music to the current directory"
    echo ""
    echo "OPTIONS:"
    echo " -i filename     read URL from input text file"
    echo " -c codec        convert to other codec e.g. \"mp3\""
    echo " -s              sane output filename to avoid special "
    echo "                 characters in filenames"
    echo " -l logfile      log downloads to file for later usage" 
    echo " -u              use updated, locale yt-dlp source"
    exit 1
}

INTERACTIVE=true
USELOCALE=false

while getopts ":i:c:sl:u" o; do
    case "${o}" in
        i)
	    INPUTFILE=${OPTARG}
	    INTERACTIVE=false
            if [ ! -f "${INPUTFILE}" ]; then
                echo "input list ${INPUTFILE} does not exist."
                usage
            fi
            ;;
        c)
            CONVERT=${OPTARG}
            ;;
	s)
	    # OK if not defined before
	    SANE=true
	    ;;
	l)
	    LOGFILE=${OPTARG}
	    ;;
	u)
	    USELOCALE=true
	    ;;
        *)
	    echo "wrong parameter usage..."
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# check if yt-dlp is installed globally
if hash yt-dlp 2>/dev/null; then
    # yt-dlp exists globally, so
    # call it directly to introduce it to hash builtin
    # and test with "hash -t yt-dlp"
    yt-dlp --version > /dev/null
else
    # no global yt-dlp found, so force
    # local usage
    USELOCALE=true
fi

if ! which jq > /dev/null; then
    echo "Please install jq on your system."
    echo " (e.g. by running \"sudo apt install jq\")"
    exit 1
fi

if ! which ffmpeg > /dev/null ; then
    echo "Please install ffmpeg on your system."
    echo " (e.g. by running \"sudo apt install ffmpeg\")"
    exit 1
fi

update_ytdl() {
    if ! which curl > /dev/null ; then
        echo "Please install curl on your system."
        echo " (e.g. by running \"sudo apt install curl\")"
        exit 1
    fi
    download_url="$(curl -s https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest | jq -r ' .assets[].browser_download_url | select( . | test("yt-dlp$"))')"
    curl -L "$download_url" > ./.bin/yt-dlp
    chmod a+x "./.bin/yt-dlp"
}

if $USELOCALE; then
    mkdir -p "./.bin"
    if [ ! -f "./.bin/yt-dlp" ]; then
        echo "Downloading yt-dlp for the first time"
	update_ytdl
    fi
    hash -p ${BASEDIR}/.bin/yt-dlp yt-dlp
    updatable=$(yt-dlp -U)
    if ! echo $updatable | grep "yt-dlp is up to date"; then
        echo "Update is needed for yt-dlp"
	update_ytdl
    fi
        
fi


echo "using $(hash -t yt-dlp) - $(yt-dlp --version)"

youtube_dl(){
    # invoke yt-dlp
    # --metadata-from-title "(?P<artist>.+?) - (?P<track>.+)[^\(\[]*[\(\[]+[^\)\]]*[\)\]]+" \
    # --embed-thumbnail - only supported by mp3 mp4
    yt-dlp -f 251/249/bestaudio \
	       -x ${CONVERT:+ --audio-format "${CONVERT}"} \
	       -o "${OUTPUT}" \
	       ${SANE:+ --restrict-filenames} \
	       --add-metadata \
	       ${@}
}
download(){
    # $1 - url or ID parsable by yt-dlp
    json=".json.txt"
    youtube_dl -J -o "random.ext" "$1" > "${json}"

    typee=$(cat ${json} | jq "._type")
    artist=$(cat "${json}" | jq ".artist")
    track=$(cat "${json}" | jq ".track")
    chapters=$(cat "${json}" | jq ".chapters")

    if [ "${typee}" == "\"playlist\"" ]; then
	playlist=$(cat "${json}" | jq -r ".title")
	OUTPUT="${playlist}/%(playlist_index)s - %(artist)s - %(track)s.%(ext)s"
	# readarray vids < <(cat ${json} | jq ".entries[] | .id" | tr -d "\"")
	# for i in ${vids[@]}; do
	#     OUTPUT="${playlist}/"
	#     echo "download $i"
	#     download $i
	# done
	# exit
    elif [ "${artist}" == "null" ] || [ "${track}" == "null" ]; then
	OUTPUT="${OUTPUT}%(title)s.%(ext)s"
    else
	OUTPUT="${OUTPUT}%(artist)s - %(track)s.%(ext)s"
    fi
	
    youtube_dl "${1}"

    if [ ! -z $LOGFILE ] ; then
	title=$(yt-dlp --get-title ${1})
	echo "$1 (${title//$'\n'/\; })" >> ${LOGFILE}
    fi

    # postprocessing
    # echo "DEBUG: $chapters"
    if [ "${chapters}" != "null" ]; then
	read -p "Chapters found! I am going to split them all! Continue (Y/n)?" choice
        case "$choice" in
          n|N ) exit ;;
          * )   ;;
        esac
	fname=$(youtube_dl --get-filename "$1")
	basefile=$(basename "${fname%.*}")	
	ext=$(echo "$basefile".*) # expand to written file
	ext=${ext##*.}          # only take extension
	echo "DEBUG: \"${basefile}\", \"${ext}\""

	mkdir -p "${basefile}"
	i=0
	while true; do
	    title=$(cat "${json}" | jq -r ".chapters[${i}] | .title")
           fname_i=$(echo ${title} |  tr -d '[:cntrl:][=/=][=$=][=!=][=?=]')
	    tstart=$(cat "${json}" | jq -r ".chapters[$i] | .start_time")
	    tend=$(cat "${json}" | jq -r ".chapters[$i] | .end_time")
	    if [ "${tstart}" == "null" ]; then
		break
	    fi
	    ffmpeg -i "${basefile}.${ext}" \
		-loglevel fatal \
		-vcodec copy \
		-acodec copy \
		-metadata:s:a:0 TITLE="${title}" \
		-ss $(date --utc --date "1970-01-01 ${tstart} sec" "+%T") \
		-to $(date --utc --date "1970-01-01 ${tend} sec" "+%T") \
               "${basefile}/$(printf "%02.0f" $i) - ${fname_i}.${ext}"
	    i=$(($i + 1))
	done
    fi
}

if ${INTERACTIVE}; then
    # interactive mode:
    echo "You can simply paste your URLs in this terminal - either with"
    echo "middle mouse button, using Ctrl+Shift+V, or right click and then"
    echo "choose the option to paste into the terminal."

    while true
    do
      echo -e "\nenter new URL"
      read url
      if [ "$url" == "" ]; then
        exit
      fi
      OUTPUT=""
      download "$url"
    done
fi

echo "${INPUTFILE}"
if [ -f ${INPUTFILE} ]; then
    cp "${INPUTFILE}" "${INPUTFILE}.tmp"
    while read line; do
	if [ ${#line} -le 2 ]; then
	    continue
	fi
	OUTPUT=""
        download ${line}
        sed -i "1d" "${INPUTFILE}.tmp"
    done < "${INPUTFILE}"
    mv "${INPUTFILE}.tmp" "${INPUTFILE}"
fi
