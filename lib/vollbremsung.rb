module Vollbremsung

  USAGE   = "Usage: vollbremsung [options] target [target [...]]"
  VERSION = '0.0.21'.freeze
  CONVERT_TYPES = ['avi','flv','mkv','mpg','mov','ogm','webm','wmv']
  FFMPEG_OPTIONS = "-map 0 -acodec copy -vcodec copy -scodec copy"
  X264_DEFAULT_PRESET = "veryfast".freeze

  class StreamDescr < Struct.new(:count,:names)
    def initialize
      super(0,[])
    end
  end

end
