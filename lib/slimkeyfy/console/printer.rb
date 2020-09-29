require 'diff-lcs'
require 'diffy'

class SlimKeyfy::Console::Printer
  def self.difference(old_line, new_line, translations)
    puts Diffy::Diff.new("#{old_line}\n", "#{new_line}\n", context: 1).to_s(:color)
    puts translations.to_s.yellow
    puts "-"*40
  end

  def self.unix_diff(bak_path, file_path)
    diff = Diffy::Diff.new(bak_path, file_path, source: 'files', context: 1).to_s(:color)
    puts diff
  end
  def self.normalize(line)
    line.sub(/^\s*/, " ")
  end
  def self.tag(old_line, translations, comment_tag)
    prettified_translations = translations.map{|k, v| "#{k}: #{v}, t('.#{k.split(".").last}')" }.join(" | ")
    "#{indentation(old_line)}#{comment_tag} #{prettified_translations}\n#{old_line}"
  end
  def self.indentation(line)
    return "" if line.nil? or line.empty?
    " " * (line.size - line.gsub(/^\s+/, "").size)
  end
end

class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end
  def red
    colorize(31)
  end
  def green
    colorize(32)
  end
  def yellow
    colorize(34)
  end
  def white
    colorize(37)
  end
end
