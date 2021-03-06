# vollbremsung

[![Gem Version](https://badge.fury.io/rb/vollbremsung.svg)](http://badge.fury.io/rb/vollbremsung)

`vollbremsung` is a [Handbrake](https://handbrake.fr) bulk encoding tool, designed to reencode a file structure to a DLNA enabled TV compatible format comfortably.

## Installation

Just run ```gem install vollbremsung```

### Dependencies

You need to have `ffmpeg`, `ffprobe` and `HandbrakeCLI` (on FreeBSD it's `HandBrakeCLI` if installed from the Portstree) somewhere in your `$PATH`.

## Usage

	vollbremsung [options] target [target [...]]

It takes target paths and probes them for suited files. If a target path is a file, it is the only match, if it is a directory all containing files with a matching file type (basically all the non MP4 multimedia types like `avi`, `flv`, `mov`, etc.) are taken. The `--recursive` option will extend the search scope to probe the sub filetree as well. It furthermore analyses each file for its structure utilising [ffmpegs](https://www.ffmpeg.org) `ffprobe` tool in order to extend Handbrakes default preset, processing *all* audio and subtitle tracks, not only the first ones.

The video streams will be converted to h.264 while audio streams will enjoy the AAC codec. Every DLNA enabled TV should be able to handle these two.

The `x264-preset ` used is `veryfast` which should be a good tradeoff most of the time. If you want to change this manually, use the `--x264-preset [PRESET]` option.

The `--delete` and `--move` option allow post processing actions. `delete` will of course remove the source file upon successful processing, while `move ` will add a `.old` file extension for archive purposes. This is always a good option, just to be sure.

Additionally, `vollbremsung` can set the MP4 title tag to the filename via the `--title` option, in case the old file title metadata is somewhat misshapen.

Per default the `m4v` file extension is used to indicate that the files contain video content. It turned out that some TVs can't handle this extension and require plain `mp4`. The `--mp4-ext` option will make `vollbremsung` create `mp4` files. You can of course rename the output files manually as well.  

If you only want to know which files would match for a given target, use the `--list-only` option. No processing will be done, just the matches printed.

In order to only match a given range of file extensions, the `--match` option accepts a comma separated list of file extensions which will replace the default match scope. Thereby this can be used to extend the matching extensions in fact by just reusing the list printed from `--help` and adding extensions.

### Complete list of options

    -d, --delete                     Delete source files after successful encoding
        --list-only                  List matching files only. Do not run processing
        --match ext1,ext2,ext3       Match only specific file extensions
        --mp4-ext                    Use 'mp4' as file extension instead of 'm4v'
    -m, --move                       Move source files to <FILENAME>.old after encoding
    -q, --quality VALUE              Set quality value to use (default is: 22)
    -r, --recursive                  Process subdirectories recursively as well
    -t, --title                      Set the MP4 metadata title tag to the filename
        --preset PRESET              Set the x264/x265 preset. Default is: veryfast
        --x265                       Use x265 encoder for HEVC conversion
        --version                    Show program version information
    -h, --help                       Show this message

## Etymology

"*vollbremsung*" means "*full application of the brake*" in german.

## Changelog

see [CHANGELOG.md](CHANGELOG.md)