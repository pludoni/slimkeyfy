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

  context "attribute keys" do
    let(:line) { 'button(class="btn btn-outline-secondary" type="button" title="Toggle" data-toggle)' }
    it {should == [
      %{button(class="btn btn-outline-secondary" type="button" :title="$t('key_base.new.toggle')" data-toggle)}, {"key_base.new.toggle"=>"Toggle"}]
    }
  end

  context "don't translate already translated" do
    let(:line) { 'button(class="btn btn-outline-secondary" type="button" :title="toggle" data-toggle)' }
    it {should == [ nil, nil]
    }
  end

  context "arial-label" do
    let(:line) { 'a(href="#" class="btn-clear" aria-label="Löschen" role="button")' }
    it {should == [ %[a(href="#" class="btn-clear" :aria-label="$t('key_base.new.loschen')" role="button")], {"key_base.new.loschen" => "Löschen"}]
    }
  end

  context "label as first attribute" do
    let(:line) { 'b-form-group(label="Sprache")' }
    it {should == [ %[b-form-group(:label="$t('key_base.new.sprache')")], {"key_base.new.sprache" => "Sprache"}]
    }
  end
  # b-modal(modal-title="Foobar")
end
