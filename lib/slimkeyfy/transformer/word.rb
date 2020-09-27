class SlimKeyfy::Transformer::Word
  attr_reader :line, :tokens, :indentation
  attr_accessor :translations

  def initialize(line, key_base, use_absolute_key)
    @line = line
    @key_base = key_base
    @use_absolute_key = use_absolute_key.is_a?(String) ? use_absolute_key == '.rb' : use_absolute_key
    @indentation = " " * (@line.size - unindented_line.size)
    @translations = {}
  end

  def as_list(delim=" ")
    delimiter_items =
      @line.
        sub(/^(\s*\|)(\w)/, "\\1 \\2").  # add a whitespace to support "|string"
        split(delim)
    items = []
    # div: div
    delimiter_items.reverse.each do |item|
      if item[/^([a-z]|\.[a-z]|#[a-z]).*:/]
        items[-1] = "#{item} #{items[-1]}"
      else
        items << item
      end
    end
    items.reverse
  end

  def unindented_line
    @line.sub(/^\s*/, "")
  end

  def head
    as_list.first
  end

  def tail
    as_list.drop(1)
  end

  def i18n_string(translation_key, args={})
    args_string = args.inject('') do |string, (k,v)|
      string += ", #{k}: (#{v})"
    end

    if @use_absolute_key
      "t('#{@key_base}.#{translation_key}'#{args_string})"
    else
      "t('.#{translation_key}'#{args_string})"
    end
  end

  def update_translation_key_hash(yaml_processor, translation)
    arguments, translation = extract_arguments(translation)
    translation_key = SlimKeyfy::Slimutils::TranslationKeyGenerator.new(translation).generate_key_name
    translation_key_with_base = "#{@key_base}.#{translation_key}"
    translation_key_with_base, translation = yaml_processor.merge!(translation_key_with_base, translation) unless yaml_processor.nil?
    @translations.merge!({translation_key_with_base => translation})
    i18n_string(extract_updated_key(translation_key_with_base), arguments)
  end

  def extract_arguments(translation)
    args = {}
    translation.scan(/\#{[^}]*}/).each_with_index do |arg, index|
      stripped_arg = arg[2..-2]
      key = arg[/\w+/]
      key = key + index.to_s if index > 0
      translation = translation.gsub(arg, "%{#{key}}")
      args[key]= stripped_arg
    end
    [args, translation]
  end

  def extract_updated_key(translation_key_with_base)
    return "" if (translation_key_with_base.nil? or translation_key_with_base.empty?)
    translation_key_with_base.split(".").last
  end
end
