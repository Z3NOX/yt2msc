**HINT**: `youtube-dl` is discontinued in favour of `yt-dlp` which is a fork of the former programm and can be used as prop in replacement"

# yt2msc
Youtube to music. Download music directly from youtube using ~~`youtube-dl`~~ `yt-dlp` and convert it to a favourable format (as mp3) with `ffmpeg`. This shell script is just a simple wrapper around `yt-dlp` which concentrates on the usage of downloading music from youtube and all other sources supported by the amazing `yt-dlp` tool (e.g. vimeo, bandcamp, soundcloud, …)

For an extensive list of supported sites, see `yt-dlp --list-extractors`

## dependencies
* `ffmpeg`
* `yt-dlp`, which can also be downloaded with this script in case your linux distribution does not provide a recent enough version
* `jq`

## usage
Clone the repo
```sh
git clone https://github.com/Z3NOX/yt2msc
```
or download the script and make it executable
```sh
wget https://github.com/Z3NOX/yt2msc/blob/master/yt2msc.sh
chmod u+x yt2msc.sh
```
After the download there are two different modes in which `yt2msc` will operate.

### interactively
The default mode is an interactive mode where you can simply drop any youtube video link, youtube playlist link or youtube ID into the shell and `yt2msc` will immediately start to download this file and save into an audio file.
```sh
# using globally installed yt-dlp
./yt2msc.sh

# using local yt-dlp script that will 
# be downloaded to ./.bin and be updated
# in the future
./yt2msc.sh -u
```

### with input file
The other mode is using an input file
```sh
# usage for using globally installed yt-dlp
./yt2msc.sh -i youtube_list.txt
```
where in `youtube_list.txt` every URL or youtube ID is saved on a separate line.

### other helpful options
You may want to convert audio files to a format which is most useful to you, do so with `-c format`:
```sh
./yt2msc.sh -c opus
./yt2msc.sh -c mp3
./yt2msc.sh -c flac
```

If you want to keep an 'history' of your downloaded files to download them later again - maybe when this script provides more functionality - you can use th `-l file` option where you define a logfile
```sh
./yt2msc.sh -l downloaded.txt
```
