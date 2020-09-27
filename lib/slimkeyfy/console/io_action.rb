class SlimKeyfy::Console::IOAction
  def self.prompt
    @prompt ||= TTY::Prompt.new
  end

  def self.yes_or_no?(msg)
    puts "#{msg} (y|n)"
    arg = STDIN.gets.chomp
    if arg =~ /[yY](es)?/
      true
    elsif arg =~ /[nN]o?/
      false
    else
      puts "Provide either (y)es or (n)o!"
      self.yes_or_no?(msg)
    end
  end
  def self.choose(msg)
    prompt.select(msg) do |menu|
      menu.default 1
      menu.choice "Use translation", "y"
      menu.choice "Skip", "n"
      menu.choice "Tag for changes", "x"
      menu.choice "Cancel and Exit", "a"
    end
  end
end
