module SlimKeyfy::Transformer
  class JsWord < Word
    def initialize(*args)
      super
      @use_absolute_key = true
    end

    def i18n_string(translation_key, args={})
      if args.keys.length > 0
        args_string = ", { #{args.map { |k, v| "#{k}: (#{v})" }.join(', ')} }"
      else
        args_string = ""
      end

      "{{ $t('#{@key_base}.#{translation_key}'#{args_string}) }}"
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
