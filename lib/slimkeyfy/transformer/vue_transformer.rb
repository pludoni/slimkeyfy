require_relative './slim_transformer'
class SlimKeyfy::Transformer::VueTransformer < SlimKeyfy::Transformer::SlimTransformer
  def self.slim?
    true
  end

  BEFORE =        /(?<before>.*[\( ^])/
  HTML_ARGUMENTS = {
    placeholder:        /(?<html_tag>[a-z\-]*placeholder=\s*)/,
    title:              /(?<html_tag>title=\s*)/,
    kind_of_title:      /(?<html_tag>[a-z\-]+title=\s*)/,
    label:              /(?<html_tag>[a-z\-]*label=\s*)/,
    description:        /(?<html_tag>description=\s*)/,
    alt:                /(?<html_tag>alt=\s*)/,
    prepend:            /(?<html_tag>prepend=\s*)/,
    append:             /(?<html_tag>append=\s*)/,
  }

  def regex_list
    HTML_ARGUMENTS.map{|_, regex| /#{BEFORE}#{regex}#{TRANSLATION}#{AFTER}/ }
  end

  def initialize(word, yaml_processor=nil)
    super
  end

  def transform
    @@mode ||= :template
    if @word.line[/^<template/]
      @@mode = :template
    elsif @word.line[/^<script/]
      @@mode = :script
    elsif @word.line[/^<style/]
      @@mode = :style
    end

    if @@mode == :style || @@mode == :script
      return nil_elem
    end
    super
  end


  # def transform
  #   require 'pry'
  #   a = super
  #   a
  # end

  def parse_html
    return nil_elem if @word.line.match(TRANSLATED)
    return nil_elem if @word.tail.join(" ")[/^{{.*}}$/]

    body = @word.tail.join(" ")
    body, tagged_with_equals = SlimKeyfy::Transformer::Whitespacer.convert_nbsp(body, @word.head)

    tagged_with_equals = "|" if tagged_with_equals == "="

    if body.match(LINK_TO) != nil
      body = link_tos(body)
    end

    translation_key = update_hashes(body)
    normalize_translation("#{tagged_with_equals} #{translation_key}")
  end

  def parse_html_arguments(line)
    regex_list.each do |regex|
      line.scan(regex) do |m_data|
        before, html_tag = m_data[0], m_data[1]
        if before[-1] == ":" # already dynamic attribute
          next
        end
        translation, after = match_string(m_data[2]), m_data[3]

        translation_key = @word.update_translation_key_hash(@yaml_processor, translation, mode = :html_argument)
        line = "#{before}:#{html_tag}#{translation_key}#{after}"
      end
    end
    normalize_translation(line)
  end
end

