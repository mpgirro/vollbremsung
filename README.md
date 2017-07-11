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
    -r, --recursive                  Process subdirectories recursively as well
    -t, --title                      Set the MP4 metadata title tag to the filename
        --x264-preset PRESET         Set the x264-preset. Default is: veryfast
        --version                    Show program version information
    -h, --help                       Show this message

## Etymology

"*vollbremsung*" means "*full application of the brake*" in german.

## Changelog

**1.0.0**

+ TODO

**0.0.21**

+ Added the `--match` option.

**0.0.20**

+ Added `webm` to the matching file extensions.

**0.0.19**

+ Fixed a bug where temporary files were not deleted when their mp4 title could not be changed.

**0.0.18**

+ Fixed a bug with multiple target directories where all but the first target were not probed correctly.

**0.0.17**

+ Added support for multiple targets.
+ Added option for `mp4` as file extension instead of `m4v`.
+ Fixed a bug which made the `PRESET` argument of `--x264-preset` optional (and the option thereby useless).

**0.0.16**

+ Fixed a bug when probing files with square braces in their path.
+ Fixed a bug where file names where not correctly extracted from the files path and the files extension.

**0.0.15**

+ Fixed another case of the bug of **0.0.13**.

**0.0.14**

+ Fixed the bug that **0.0.13** should have fixed.

**0.0.13**

+ Fixed a bug which did not output the correct relative path of a file based on the target path.

**0.0.12**

+ Changed audio codec to AAC only. AC3, DTSHD, DTS and MP3 audio streams will no longer be passed through any more.
+ Changed file extension of the output files to `m4v`.

**0.0.11**

+ Improved help message.
+ Fixed a bug where target paths ending with a / where not proved correctly.

**0.0.10**

+ Added an option to show the program version number.
+ Added a descent help message.

**0.0.9**

+ Added `.ogm` to the matching file extensions.
+ Added a specific handbrake gem version to the dependencies.
+ Added `--list-only` option.
+ Added `--x264-preset` option.

**0.0.8**

+ Turned the simple ruby script to a RubyGem.
