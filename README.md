# yt2msc
Youtube to music. Download music directly from youtube using youtube-dl and convert it to a favourable format (as mp3) with ffmpeg. This shell script is just a simple wrapper around youtube-dl which concentrates on the usage of downloading music from youtube and all other sources supported by the amazing `youtube-dl` tool (e.g. vimdeo, bandcamp, soundcloud, …)

For an extensive list of supported sites, see `youtube-dl --list-extractors`

## dependencies
* `ffmpeg`
* `youtube-dl`, which can also be downloaded with this script in case your linux distribution does not provide a recent enough version

## usage
There are two different modes in which yt2msc will operate.

### interactively
The default mode is an interactive mode where you can simply drop any youtube video link, youtube playlist link or youtube ID into the shell and yt2msc will immediately start to download this file and save into an audio file.
```sh
# using globally installed youtube-dl
./yt2msc.sh

# using local youtube-dl script that will 
# be downloaded to ./.bin and be updated
# in the future
./yt2msc.sh -u
```

### with input file
The other mode is using an input file
```sh
# usage for using globally installed youtube-dl
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
