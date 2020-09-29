class SlimKeyfy::Console::Translate

  attr_reader :original_file_path, :bak_path

  def initialize(options={})
    @extension = options[:ext]
    @use_absolute_key = options.key?(:use_absolute_key) ? options[:use_absolute_key] : @extension == '.rb'
    @transformer = transformer
    @original_file_path = options[:input]
    @no_backup = options.fetch(:no_backup, false)
    @bak_path = SlimKeyfy::Slimutils::MFileUtils.backup(@original_file_path)
    @content = self.class.join_multiline( SlimKeyfy::Slimutils::FileReader.read(@bak_path).split("\n") )
    @file_path = SlimKeyfy::Slimutils::MFileUtils.create_new_file(@original_file_path)
    @key_base = generate_key_base
    @yaml_processor = create_yaml_processor(options)
    @new_content = []
    @changes = false
  end

  def transformer
    if @extension == "slim"
      SlimKeyfy::Transformer::SlimTransformer
    elsif @extension == "rb"
      SlimKeyfy::Transformer::ControllerTransformer
    else
      puts "Unknown extension type!"
      exit
    end
  end

  def create_yaml_processor(options)
    SlimKeyfy::Slimutils::YamlProcessor.new(options[:locale], @key_base, options.fetch(:yaml_output, nil))
  end

  def generate_key_base
    SlimKeyfy::Slimutils::BaseKeyGenerator.generate_key_base_from_path(@original_file_path, @extension)
  end

  def stream_mode
    @content.each_with_index do |old_line, idx|
      word = SlimKeyfy::Transformer::Word.new(old_line, @key_base, @use_absolute_key)
      new_line, translations = @transformer.new(word, @yaml_processor).transform
      if translations_are_invalid?(translations)
        @yaml_processor.delete_translations(translations)
        update_with(idx, old_line)
      else
        process_new_line(idx, old_line, new_line, translations)
        @changes = true
      end
    end
    SlimKeyfy::Slimutils::FileWriter.write(@file_path, @new_content.join("\n"))
    finalize!
  rescue StandardError => e
    SlimKeyfy::Slimutils::MFileUtils.restore(@bak_path, @original_file_path)
    raise e
  end

  def change_key(idx, old_line, new_line, translations)
    old_key = translations.first.first
    parts = old_key.split('.')
    prefix = parts[0...-1].join('.')
    new_key = prefix + "." + TTY::Prompt.new.ask("Key: #{prefix}.", default: parts[-1])

    update_with(idx, old_line)
    @yaml_processor.delete_translations(translations)

    translations[new_key] = translations.delete(old_key)

    @yaml_processor.merge!(new_key, translations[new_key])
    new_line = new_line.sub(old_key, new_key)

    process_new_line(idx, old_line, new_line, translations)
  end

  def process_new_line(idx, old_line, new_line, translations)
    SlimKeyfy::Console::Printer.difference(old_line, new_line, translations)
    case SlimKeyfy::Console::IOAction.choose("Changes wanted?")
      when "y" then update_with(idx, new_line)
      when "c"
        change_key(idx, old_line, new_line, translations)
      when "n" then
        update_with(idx, old_line)
        @yaml_processor.delete_translations(translations)
      when "x" then
        update_with(idx, SlimKeyfy::Console::Printer.tag(old_line, translations, comment_tag))
        @yaml_processor.delete_translations(translations)
      when "a" then
        SlimKeyfy::Slimutils::MFileUtils.restore(@bak_path, @original_file_path)
        puts "Aborted!"
        exit
    end
  end

  def finalize!
    if @changes
      SlimKeyfy::Console::Printer.unix_diff(@bak_path, @original_file_path)
      if SlimKeyfy::Console::IOAction.yes_or_no?("Do you like to save your changes?")
        @yaml_processor.store!
        puts "Saved! at #{@original_file_path}"
        SlimKeyfy::Slimutils::MFileUtils.rm(@bak_path) if @no_backup
      else
        SlimKeyfy::Slimutils::MFileUtils.restore(@bak_path, @original_file_path)
        puts "Restored!"
      end
    else
      SlimKeyfy::Slimutils::MFileUtils.restore(@bak_path, @original_file_path)
      puts "Nothing was changed!"
    end
  end

  def update_with(idx, line)
    @new_content[idx] = line
  end

  def translations_are_invalid?(translations)
    translations.nil? or translations.empty?
  end

  def comment_tag
    @transformer.slim? ? "//" : "#"
  end

  def self.join_multiline( strings_array )
    result = []
    joining_str = ''
    indent_length = 0
    long_str_start = /^[ ]+\| */
    long_str_indent = /^[ ]+/
    long_str_indent_with_vertical_bar = /^[ ]+\| */
    strings_array.each do |str|
      if joining_str.empty?
        if str[long_str_start]
          joining_str = str
          indent_length = str[long_str_start].length
        else
          result << str
        end
      #multiline string continues with spaces
      elsif ( str[long_str_indent] && str[long_str_indent].length.to_i >= indent_length )
        joining_str << str.gsub( long_str_indent, ' ' )
      #muliline string continues with spaces and vertical bar with same indentation
      elsif str[long_str_indent_with_vertical_bar] && str[long_str_indent_with_vertical_bar].length.to_i == indent_length
        joining_str << str.gsub( long_str_indent_with_vertical_bar, ' ' )
      #multiline string ends
      else
        result << joining_str
        joining_str = ''
        indent_length = 0
        result << str
      end
    end
    result << joining_str unless joining_str.empty?

    result
  end
end
