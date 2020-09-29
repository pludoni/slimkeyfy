require_relative '../../lib/slimkeyfy/'
require 'pry'

describe "VueTransformer" do
  let( :key_base ) { "key_base.new"}
  let( :line ) { "" }
  let( :word ) { SlimKeyfy::Transformer::JsWord.new(line, key_base, true) }

  subject  { SlimKeyfy::Transformer::VueTransformer.new(word, nil).transform }

  context "with | and regular whitespace" do
    let(:line) { "|  Hello World!" }
    it {should == [
      "| {{ $t('key_base.new.hello_world') }}",
      {"#{key_base}.hello_world" => "Hello World!"}]
    }
  end

  context "ignores raw interpolated" do
    let(:line) { "| {{filename}}" }
    it {should == [ nil, nil ] }
  end

  context "with | and arguments" do
    let(:line) { "|  Hello World {{user}}!" }
    it {should == [
      "| {{ $t('key_base.new.hello_world_user', { user: (user) }) }}",
      {"#{key_base}.hello_world_user" => "Hello World {user}!"}]
    }
  end

  context "with html prefix" do
    let(:line) { "button.btn Speichern" }
    it {should == [
      "button.btn {{ $t('key_base.new.speichern') }}", {"key_base.new.speichern"=>"Speichern"}]
    }
  end
end
