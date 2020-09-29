module SlimKeyfy::Transformer
  class JsWord < Word
    def initialize(*args)
      super
      @use_absolute_key = true
    end

    def template_i18n_string(translation_key, args={})
      if args.keys.length > 0
        args_string = ", { #{args.map { |k, v| "#{k}: (#{v})" }.join(', ')} }"
      else
        args_string = ""
      end

      "{{ $t('#{@key_base}.#{translation_key}'#{args_string}) }}"
    end

    def string_i18n_string(translation_key, args={})
      if args.keys.length > 0
        args_string = ", { #{args.map { |k, v| "#{k}: (#{v})" }.join(', ')} }"
      else
        args_string = ""
      end

      %["$t('#{@key_base}.#{translation_key}'#{args_string})"]
    end

    def update_translation_key_hash(yaml_processor, translation, mode = :template)
      arguments, translation = extract_arguments(translation)
      translation_key = SlimKeyfy::Slimutils::TranslationKeyGenerator.new(translation).generate_key_name
      translation_key_with_base = "#{@key_base}.#{translation_key}"
      translation_key_with_base, translation = yaml_processor.merge!(translation_key_with_base, translation) unless yaml_processor.nil?
      @translations.merge!({translation_key_with_base => translation})
      if mode == :template
        template_i18n_string(extract_updated_key(translation_key_with_base), arguments)
      else
        string_i18n_string(extract_updated_key(translation_key_with_base), arguments)
      end
    end

    def extract_arguments(translation)
      args = {}
      translation.scan(/\{\{([^}]*)\}\}/).each_with_index do |stripped_arg, index|
        arg = Regexp.last_match[0]
        key = arg[/\w+/]
        key = key + index.to_s if index > 0
        translation = translation.gsub(arg, "{#{key}}")
        args[key]= stripped_arg[0]
      end
      [args, translation]
    end
  end
end
