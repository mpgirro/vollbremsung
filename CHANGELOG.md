# Changelog

**1.0.2**

+ Fixes size difference ratio calculation.

**1.0.1**

+ Fixes an error where the application could terminate unintentionally

**1.0.0**

+ Total refactoring of the codebase, new project structure
+ Support for transcoding to HEVC with the `--x265` flag
+ Support for passing quality value to Handbrake, with the `-q` option

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
