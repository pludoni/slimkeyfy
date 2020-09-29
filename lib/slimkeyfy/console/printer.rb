class SlimKeyfy::Console::Printer
  def self.difference(old_line, new_line, translations)
    puts "#{'-'.red} #{normalize(old_line).red}"
    puts "#{'+'.green} #{normalize(new_line).green} => #{translations.to_s.yellow}"
    puts "-"*40
  end
  def self.unix_diff(bak_path, file_path)
    result = "Please install colordiff or diff (brew install colordiff)"
    colordiff, diff, wdiff = `which colordiff`, `which diff`, `which wdiff`
    if !wdiff.empty? and !colordiff.empty?
      result = `wdiff #{bak_path} #{file_path} | colordiff`
    elsif not colordiff.empty?
      result = `colordiff #{bak_path} #{file_path}`
    elsif not diff.empty?
      result =`diff #{bak_path} #{file_path}`
    end
    if result.nil? or result.strip.empty?
      puts "No changes for comparison found!"
    else
      puts "#{result}"
    end
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
