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
    echo "Uses youtube-dl to download and convert music to the current directory"
    echo ""
    echo "OPTIONS:"
    echo " -i filename     read URL from input text file"
    echo " -c codec        convert to other codec e.g. \"mp3\""
    echo " -s              sane output filename to avoid special "
    echo "                 characters in filenames"
    echo " -l logfile      log downloads to file for later usage" 
    echo " -u              use updated, locale youtube-dl source"
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

if $USELOCALE; then
    mkdir -p "./.bin"
    if [ ! -f "./.bin/youtube-dl" ]; then
	wget "https://yt-dl.org/downloads/latest/youtube-dl" -O "./.bin/youtube-dl"
	chmod a+x "./.bin/youtube-dl"
    fi
    hash -p ${BASEDIR}/.bin/youtube-dl youtube-dl
    youtube-dl -U
fi

# call youtube-dl directly to introduce it to hash builtin
youtube-dl --version > /dev/zero
echo "using $(hash -t youtube-dl) - $(youtube-dl --version)"

youtube_dl(){
    # invoke youtube-dl
    # --metadata-from-title "(?P<artist>.+?) - (?P<track>.+)[^\(\[]*[\(\[]+[^\)\]]*[\)\]]+" \
    youtube-dl -f 251/249/bestaudio \
	       -x ${CONVERT:+ --audio-format "${CONVERT}"} \
	       -o '%(playlist)s/%(artist)s - %(track)s.%(ext)s' \
	       ${SANE:+ --restrict-filenames} \
	       --add-metadata \
	       "${1}"

    if [ ! -z $LOGFILE ] ; then
	title=$(youtube-dl --get-title ${1})
	echo "$1 (${title//$'\n'/\; })" >> ${LOGFILE}
    fi
}

if ${INTERACTIVE}; then
    # interactive mode:
    echo "You can simply paste your URLs in this terminal - either with"
    echo "middle mouse button, using Ctrl+Shft+V, or right click and then"
    echo "choose the option to paste into the terminal."

    while true
    do
      echo -e "\nenter new URL"
      read url
      if [ "$url" == "" ]; then
        exit
      fi
      youtube_dl "$url"
    done
fi

echo "${INPUTFILE}"
if [ -f ${INPUTFILE} ]; then
    cp "${INPUTFILE}" "${INPUTFILE}.tmp"
    while read line; do
	if [ ${#line} -le 2 ]; then
	    continue
	fi
	youtube_dl ${line}
        sed -i "1d" "${INPUTFILE}.tmp"
    done < "${INPUTFILE}"
    mv "${INPUTFILE}.tmp" "${INPUTFILE}"
fi
