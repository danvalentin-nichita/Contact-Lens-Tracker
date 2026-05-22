#!/usr/bin/env ruby
require 'json'
require 'csv'

# Paths (relative to this script)
LOCALIZABLE_PATH = File.expand_path('../Localizable.xcstrings', __dir__)
CSV_PATH = File.expand_path('../Localizable_placeholder.csv', __dir__)

# Load existing xcstrings (JSON format)
content = File.read(LOCALIZABLE_PATH)
json = JSON.parse(content)
strings = json['strings']

CSV.open(CSV_PATH, 'w', write_headers: true, headers: %w[key en it ro ru]) do |csv|
  strings.each do |key, data|
    en_val = data.dig('localizations', 'en', 'stringUnit', 'value')
    it_val = data.dig('localizations', 'it', 'stringUnit', 'value')
    # Placeholder values for missing languages
    ro_val = en_val
    ru_val = en_val

    data['localizations'] ||= {}
    data['localizations']['ro'] ||= { 'stringUnit' => { 'state' => 'translated', 'value' => ro_val } }
    data['localizations']['ru'] ||= { 'stringUnit' => { 'state' => 'translated', 'value' => ru_val } }

    csv << [key, en_val, it_val, ro_val, ru_val]
  end
end

# Write back pretty‑printed xcstrings file
File.write(LOCALIZABLE_PATH, JSON.pretty_generate(json))
puts "Added placeholder ro/ru translations and generated CSV at #{CSV_PATH}"
