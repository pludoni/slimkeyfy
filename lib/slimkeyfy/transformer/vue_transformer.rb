require_relative './slim_transformer'
class SlimKeyfy::Transformer::VueTransformer < SlimKeyfy::Transformer::SlimTransformer
  def self.slim?
    true
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
end

