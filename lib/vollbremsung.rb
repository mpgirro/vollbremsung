module Vollbremsung

  USAGE   = "Usage: vollbremsung [options] target [target [...]]"
  VERSION = '0.0.22'.freeze
  CONVERT_TYPES = ['avi','flv','mkv','mpg','mov','ogm','webm','wmv']
  FFMPEG_OPTIONS = "-map 0 -acodec copy -vcodec copy -scodec copy"
  FFPROBE_OPTIONS = "-v quiet -print_format json -show_format -show_streams"
  X264_DEFAULT_PRESET = "veryfast".freeze

  class StreamDescr < Struct.new(:count,:names)
    def initialize
      super(0,[])
    end
  end

  def log(msg)
    puts "["+Time.new.strftime("%Y-%m-%d %H:%M:%S")+"] #{msg}"
  end

  def ffprobe(file)
    stdout,stderr,status = Open3.capture3("ffprobe #{Vollbremsung::FFPROBE_OPTIONS} \"#{file}\"")
    if status.success?
      return JSON.parse(stdout)
    else
      STDERR.puts stderr
      return nil
    end
  end

  def crawl(targets, recursive)
    scope = recursive ? "/**/*" : "/*"
    targets.each do |target|

      if File.directory?(target)

        log "probing for target files in #{File.absolute_path(target) + scope}"
        log "files found:"

        Dir[escape_glob(File.absolute_path(target)) + scope].sort.each do |file|
          unless File.directory?(file)
            if options[:match_list].include?(File.extname(file).downcase[1..-1])
              puts "* " + File.absolute_path(file)[File.absolute_path(target).length+1..-1]
              target_files << [file,target] # file and provided target_dir
            end
          end
        end

      else
        puts "* " + target
        target_files << [File.absolute_path(target),File.absolute_path(target)]
      end

    end
  end

  def parse_metadata(metadata)
    astreams = Vollbremsung::StreamDescr.new
    sstreams = Vollbremsung::StreamDescr.new

    metadata['streams'].each do |stream|
      case stream['codec_type']
      when 'audio'
        astreams.count += 1
        astreams.names << stream['tags']['title'] unless stream['tags'].nil? || stream['tags']['title'].nil?
      when 'subtitle'
        sstreams.count += 1
        sstreams.names << stream['tags']['title'] unless stream['tags'].nil? || stream['tags']['title'].nil?
      else
        # this is attachment stuff, like typefonts --> ignore
      end
    end

    return astreams, sstreams
  end

  def full_outpath(infile)
    infile_basename = File.basename(infile)
    infile_basename_noext = File.basename(infile, File.extname(infile)) # without ext
    infile_dirname = File.dirname(infile)
    infile_path_noext = File.join(infile_dirname, infile_basename_noext)
    infile_relative_path = #File.directory?(TARGET_PATH) ? infile[TARGET_PATH.length+1..-1] : File.basename(TARGET_PATH)
      if File.directory?(target_dir)
        File.absolute_path(infile)[File.absolute_path(target_dir).length+1..-1]
      else
        File.basename(target_dir)
      end

    outfile = "#{infile_path_noext}.#{options[:extension]}"

    return outfile, infile_relative_path
  end

  def convert(infile, outfile, astreams, sstreams, x264_preset=Vollbremsung::X264_DEFAULT_PRESET)

  #%x( #{HANDBRAKE_CLI} #{HANDBRAKE_OPTIONS} --audio #{(1..astreams.count).to_a.join(',')} --aname #{astreams.names.join(',')} --subtitle #{(1..sstreams.count).to_a.join(',')} -i \"#{infile}\" -o \"#{outfile}\" 2>&1 )

    begin
        HandBrake::CLI.new.input(infile).encoder('x264').quality('20.0').aencoder('faac').
        ab('160').mixdown('dpl2').arate('Auto').drc('0.0').format('mp4').markers.
        audio_copy_mask('aac').audio_fallback('ffac3').x264_preset(options[:x264_preset]).
        loose_anamorphic.modulus('2').audio((1..astreams.count).to_a.join(',')).aname(astreams.names.join(',')).
        subtitle((1..sstreams.count).to_a.join(',')).output(outfile)

        # if we make it here, encoding went well
        Vollbremsung.log "SUCCESS: encoding done"
        return true
      rescue
        Vollbremsung.log "ERROR: Handbrake exited with an error"
        return false
      end # HandBrake::CLI    
  end

  def write_mp4_title(infile, outfile)

    Vollbremsung.log "setting MP4 title"

    infile_noext = File.join( File.dirname(infile), File.basename(infile,File.extname(infile)))
    tmpfile = infile_noext + ".tmp.mp4"

    %x( ffmpeg -i \"#{outfile}\" -metadata title=\"#{infile_basename_noext}\" #{Vollbremsung::FFMPEG_OPTIONS} \"#{tmpfile}\" 2>&1 )

    # if successful, either delete old file and replace with new, or delete the broken tempfile if it exists
    if $?.exitstatus == 0
      begin
        File.delete outfile
        File.rename tmpfile, outfile
      rescue
        Vollbremsung.log "ERROR: moving #{tmpfile} to #{outfile}"
      end
    else
      Vollbremsung.log "ERROR: MP4 title could not be changed"
      File.delete tmpfile
    end
  end

end
