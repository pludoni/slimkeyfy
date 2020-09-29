require 'tty-prompt'

class SlimKeyfy::Console::IOAction
  def self.prompt
    @prompt ||= TTY::Prompt.new
  end

  def self.yes_or_no?(msg)
    prompt.yes?(msg)
  end

  def self.choose(msg)
    prompt.select(msg) do |menu|
      menu.enum "."
      menu.default 1
      menu.choice "Use this translation", "y"
      menu.choice "Change translation key", "c"
      menu.choice "Skip", "n"
      menu.choice "Tag for changes", "x"
      menu.choice "Cancel and Exit", "a"
    end
  end
end
