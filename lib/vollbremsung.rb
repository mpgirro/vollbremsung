require "vollbremsung/version"
require 'logger'

module Vollbremsung

  USAGE               = "Usage: vollbremsung [options] target [target [...]]"
  CONVERT_TYPES       = ['avi','flv','mkv','mpg','mov','ogm','webm','wmv']
  FFMPEG_OPTIONS      = "-map 0 -acodec copy -vcodec copy -scodec copy"
  FFPROBE_OPTIONS     = "-v quiet -print_format json -show_format -show_streams"
  DEFAULT_ENCODER     = "x264".freeze
  DEFAULT_PRESET      = "veryfast".freeze
  DEFAULT_QUALITY     = 22

  case RUBY_PLATFORM
  when /darwin/ then 
    HANDBRAKE_CLI = "HandBrakeCLI".freeze
  else 
    HANDBRAKE_CLI = "HandbrakeCLI".freeze
  end

  class StreamDescr < Struct.new(:count,:names)
    def initialize
      super(0,[])
    end
  end

  class Brake

    def initialize
      @logger = Logger.new STDOUT
      @logger.level = Logger::INFO
      #@logger.datetime_format = '%Y-%m-%d %H:%M:%S '
      @logger.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
        if severity == "INFO" or severity == "WARN"
            "[#{date_format}] #{severity}  : #{msg}\n"
        else        
            "[#{date_format}] #{severity} : #{msg}\n"
        end
      end # proc do
    end # def initialize

    # square brackets have a special meaning in the context of shell globbing
    # --> escape them in order to find files in directories with [, ], {, }
    # symbols in their path
    private
    def escape_glob(s)
      s.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
    end

    private
    def ffprobe(file)
      stdout,stderr,status = Open3.capture3("ffprobe #{Vollbremsung::FFPROBE_OPTIONS} \"#{file}\"")
      if status.success?
        return JSON.parse(stdout)
      else
        STDERR.puts stderr
        return nil
      end
    end # def ffprobe

    private
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

    private
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

    private
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

    private
    def run_handbrake(infile, outfile, astreams, sstreams, options)

      handbrake_cmd = 
        %{ #{HANDBRAKE_CLI} \
          --encoder #{options[:encoder]} \
          --encoder-preset #{options[:preset]} \
          --quality #{options[:quality]} \
          --aencoder faac \
          --audio-copy-mask aac \
          --audio-fallback ffac3 \
          --loose-anamorphic --modulus 2 \
          --audio #{(1..astreams.count).to_a.join(',')} \
          --aname #{astreams.names.join(',')} \
          --subtitle #{(1..sstreams.count).to_a.join(',')} \
          -i \"#{infile}\" -o \"#{outfile}\" 2>&1 
        }
      #@logger.info "running handbrake cmd: #{handbrake_cmd}"
      %x( #{handbrake_cmd} )

      if $?.exitstatus == 0
        @logger.info "encoding done"
        return true
      else
        @logger.error "Handbrake exited with error code #{$?.exitstatus}"
        return false
      end 
    end # def run_handbrake

    private
    def write_mp4_title(infile, outfile)

      @logger.info "setting MP4 title"

      infile_noext = File.join( File.dirname(infile), File.basename(infile,File.extname(infile)))
      tmpfile = infile_noext + ".tmp.mp4"

      # TODO check if ffmpeg does exists (should if ffprobe is availabe, but just to make sure)

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

    private
    def ratio(infile, outfile)
      begin
        return "%.2f" % (File.size(outfile).to_f / File.size(infile).to_f)
      rescue
        return "UNAVAILABLE"
      end
    end

    public
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

          success = run_handbrake(infile, outfile, astreams, sstreams, options)

          if success
            @logger.info "compression ratio: " + ratio(outfile, infile)

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

        @logger.info "🚗  finally came to a halt"
      end # items.empty?
    end # def process
  end # class Brake

  def process(targets, options)

    brake = Vollbremsung::Brake.new
    brake.process(targets, options)

  end # def process
  module_function :process

end # module Vollbremsung
