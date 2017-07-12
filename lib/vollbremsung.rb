require "vollbremsung/version"
require 'logger'

module Vollbremsung

  USAGE               = "Usage: vollbremsung [options] target [target [...]]"
  CONVERT_TYPES       = ['avi','flv','mkv','mpg','mov','ogm','webm','wmv']
  FFMPEG_OPTIONS      = "-map 0 -acodec copy -vcodec copy -scodec copy"
  FFPROBE_OPTIONS     = "-v quiet -print_format json -show_format -show_streams"
  X264_DEFAULT_PRESET = "veryfast".freeze

  case RUBY_PLATFORM
    when /darwin/ then HANDBRAKE_CLI = "HandBrakeCLI"
    else HANDBRAKE_CLI = "HandbrakeCLI"
  end

#  def log(msg)
#    puts "["+Time.new.strftime("%Y-%m-%d %H:%M:%S")+"] #{msg}"
#  end

  class StreamDescr < Struct.new(:count,:names)
    def initialize
      super(0,[])
    end
  end

  class Brake

    def initialize
      @logger = Logger.new STDOUT
      @logger.level = Logger::INFO
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end

    def ffprobe(file)
      stdout,stderr,status = Open3.capture3("ffprobe #{Vollbremsung::FFPROBE_OPTIONS} \"#{file}\"")
      if status.success?
        return JSON.parse(stdout)
      else
        STDERR.puts stderr
        return nil
      end
    end # def ffprobe

    def match_files(targets, match_extensions, recursive)
      scope = recursive ? "/**/*" : "/*"
      matches = []
      targets.each do |target|

        if File.directory?(target)

          @logger.info "probing for target files in #{File.absolute_path(target) + scope}"
          @logger.info "files found:"

          Dir[escape_glob(File.absolute_path(target)) + scope].sort.each do |file|
            unless File.directory?(file)
              if match_extensions.include?(File.extname(file).downcase[1..-1])
                puts "* " + File.absolute_path(file)[File.absolute_path(target).length+1..-1]
                matches << [file,target] # file and provided target_dir
              end
            end
          end

        else
          puts "* " + target
          matches << [File.absolute_path(target),File.absolute_path(target)]
        end

      end

      return matches
    end # def match_files

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
    end # def parse_metadata

    def full_outpath(infile, target_dir, extension)
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

      outfile = "#{infile_path_noext}.#{extension}"

      return outfile, infile_relative_path
    end # def full_outpath

    def run_handbrake(infile, outfile, astreams, sstreams, x264_preset=Vollbremsung::X264_DEFAULT_PRESET)

      begin
          #HandBrake::CLI.new.input(infile).encoder('x264').quality('20.0').aencoder('faac').
          #ab('160').mixdown('dpl2').arate('Auto').drc('0.0').format('mp4').markers.
          #audio_copy_mask('aac').audio_fallback('ffac3').x264_preset(x264_preset).
          #loose_anamorphic.modulus('2').audio((1..astreams.count).to_a.join(',')).aname(astreams.names.join(',')).
          #subtitle((1..sstreams.count).to_a.join(',')).output(outfile)
          cmd = p %{ #{HANDBRAKE_CLI} \
              --encoder x265 \
              --quality 20.0 \
              --aencoder faac \
              --audio-copy-mask aac \
              --audio-fallback ffac3 \
              --x264-preset #{x264_preset} \
              --loose-anamorphic --modulus 2 \
              --audio #{(1..astreams.count).to_a.join(',')} \
              --aname #{astreams.names.join(',')} \
              --subtitle #{(1..sstreams.count).to_a.join(',')} \
              -i \"#{infile}\" -o \"#{outfile}\" 2>&1 }
          #@logger.info "running handbrake cmd: #{cmd}"
          %x( #{cmd} )

          if $?.exitstatus == 0
            # if we make it here, encoding went well
            @logger.info "SUCCESS: encoding done"
            return true
          else
            @logger.error "Handbrake exited with error code #{$?.exitstatus}"
            return false
          end
        rescue
          @logger.error "Handbrake exception"
          return false
        end # HandBrake::CLI    
    end # def run_handbrake

    def write_mp4_title(infile, outfile)

      @logger.info "setting MP4 title"

      infile_noext = File.join( File.dirname(infile), File.basename(infile,File.extname(infile)))
      tmpfile = infile_noext + ".tmp.mp4"

      %x( ffmpeg -i \"#{outfile}\" -metadata title=\"#{infile_basename_noext}\" #{Vollbremsung::FFMPEG_OPTIONS} \"#{tmpfile}\" 2>&1 )

      # if successful, either delete old file and replace with new, or delete the broken tempfile if it exists
      if $?.exitstatus == 0
        begin
          File.delete outfile
          File.rename tmpfile, outfile
        rescue
          @logger.error "moving #{tmpfile} to #{outfile}"
        end
      else
        @logger.error "MP4 title could not be changed"
        File.delete tmpfile
      end
    end # def write_mp4_title    

    def process(targets, options)

      matches = match_files(ARGV, options[:match_extensions], options[:recursive])

      if options[:list_only]
        exit 0
      end

      if matches.empty?
        @logger.info "no files found to process"
        exit 0
      else

        matches.each do |infile, target_dir|

          metadata = ffprobe(infile)
          if metadata.nil?
            @logger.error "could not retrieve metadata -- skipping file"
            next
          end

          astreams, sstreams = parse_metadata(metadata)
          outfile, infile_relative_path = full_outpath(infile, target_dir, options[:extension])

          @logger.info "processing: #{infile_relative_path}"

          success = run_handbrake(infile, outfile, astreams, sstreams, options[:x264_preset])

          if success
            #infile_size = File.size(infile)
            #outfile_size = File.size(outfile)

            @logger.info "compression ratio: %.2f" % (File.size(outfile).to_f / File.size(infile).to_f)

            if options[:title]
              write_mp4_title(infile, outfile)
            end # if options[:title]

            if options[:move]
              @logger.info "moving source file to *.old"
              File.rename(infile, "#{infile}.old") rescue @logger.error "could not rename source file"
            elsif options[:delete]
              @logger.info "deleting source file"
              File.delete(infile) rescue @logger.error "could not delete source file"
            end

          end # if success
        end # target_files.each

        @logger.info "🚗 finally come to a halt"
      end # items.empty?
    end # def process

  end # class Brake

  def process(targets, options)

    brake = Vollbremsung::Brake.new
    brake.process(targets, options)

  end # def process
  module_function :process

end # module Vollbremsung
