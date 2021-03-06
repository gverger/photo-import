require 'tty-progressbar'
require 'exif' # brew install libexif
require 'time'
require 'mediainfo'

class Syncer
  attr_reader :in_dir, :out_dir
  def initialize(in_dir, out_dir)
    @in_dir = in_dir
    @out_dir = out_dir
  end

  def copy
    bar = TTY::ProgressBar.new("Copying #{files.size} files [:bar]", total: files.size)
    files.each do |file|
      copy_file(file)
      import_config.update_import_time(files_with_times[file])
      bar.advance
    end
  end

  def copy_file(file)
    folder = out_folder(file)
    FileUtils.mkdir_p(folder)
    copied_file = File.join(folder, File.basename(file))
    FileUtils.cp(file, copied_file) unless File.exist?(copied_file)
  end

  def files
    @files ||= files_with_times.keys
  end

  def files_with_times
    @files_with_times ||=
      directory
      .files_with_times
      .select { |_file, time| time > last_imported_time }
      .to_h
  end

  def directory
    @directory ||= Directory.new(in_dir)
  end

  def max_imported_time
    files_with_times.values.max
  end

  def out_folder(file)
    time = files_with_times[file]
    File.join(out_dir, time.strftime('%Y'), time.strftime('%Y-%m'))
  end

  def import_config
    @import_config ||= ImportConfig.new(in_dir, out_dir)
  end

  def last_imported_time
    import_config.last_imported_time
  end
end

class Directory
  attr_reader :dir
  def initialize(dir)
    @dir = dir
  end
  def files
    @files ||= files_with_times.keys
  end

  def images
    @images ||= Dir[File.join(dir, '*.{JPEG,JPG,jpg,jpeg}')].map { |file| Image.new(file) }
  end

  def movies
    @movies ||= Dir[File.join(dir, '*.{MOV,MP4,mov,mp4}')].map { |file| Movie.new(file) }
  end

  def files_with_times
    @files_with_times ||=
      (images + movies)
      .map { |file| [file.file, file.time] }
      .to_h
  end

  def max_time
    files_with_times.values.max
  end

end

class Image
  attr_reader :file
  def initialize(file)
    @file = file
  end

  def time
    @time ||= begin
                data = Exif::Data.new(File.open(file))
                str_time = data.date_time_original || data.date_time
                Time.strptime(str_time, '%Y:%m:%d %H:%M:%S')
              end
  end
end

class Movie
  attr_reader :file
  def initialize(file)
    @file = file
  end

  def time
    @time ||=
      MediaInfo.from(file).video&.encoded_date ||
      Time.parse(File.basename(file).split('.').first)
  end
end

class ImportConfig
  DEFAULT_CONFIG_FILE = '.import'.freeze
  DEFAULT_TIME = Time.parse('2000-01-01')

  attr_reader :in_dir, :out_dir, :config_file_name
  def initialize(in_dir, out_dir, config_file_name = DEFAULT_CONFIG_FILE)
    @in_dir = in_dir
    @out_dir = out_dir
    @config_file_name = config_file_name
  end

  def import_id
    @import_id ||= `df #{in_dir} | awk 'END{print $1}'`.strip
  end

  def last_imported_time
    config[:time]
  end

  def config_file
    @config_file ||= File.join(out_dir, config_file_name)
  end

  def configs
    @configs ||= if File.exist?(config_file)
                   YAML.load_file(config_file)
                 else
                   [default_config]
                 end
  end

  def config
    @config ||=
      begin
        conf = configs.find { |config| config[:id] == import_id }
        unless conf
          conf = default_config
          configs << conf
        end
        conf
      end
  end

  def update_import_time(time)
    config[:time] = [config[:time], time].max
    save_file
  end

  def save_file
    File.open(config_file, 'w') do |file|
      file.write(YAML.dump(configs))
    end
  end

  def default_config
    { id: import_id, time: last_imported }
  end

  def last_imported
    return DEFAULT_TIME unless last_out_dir

    Directory.new(last_out_dir).max_time
  end

  def last_out_dir
    @last_out_dir ||= Dir["#{out_dir}/20*/*"].max
  end
end

syncer = Syncer.new('tmp/in', 'tmp/out')
