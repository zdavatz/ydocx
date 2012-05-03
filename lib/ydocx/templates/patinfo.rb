#!/usr/bin/env ruby
# encoding: utf-8

require 'ydocx/templates/fachinfo'

module YDocx
  class Parser
    private
    def parse_as_block(r, text)
      text = text.strip
      # TODO
      # Franzoesisch
      chapters = {
        # ignore '' => /^Information\s+f&uuml;r\sPatientinnen\s+und\s+Patienten$/u, # 1
        'Name'                => /^Name\s+des\s+Pr&auml;parates$/u, # 2
        'Eigensch.'           => /^Was\s+ist\s+\w+\s+und\s+wann\s+wird\s+es\s+angewendet\s*\?$/u, # 3
        'Ab&auml;nderung'     => /^Was\s+sollte\s+dazu\s+beachtet\s+werden\s*\?$/u, # 4
        'Kontraind.'          => /^Wann\s+darf\s+\w\s+nicht\s+eingenommen\s*\/\s*angewendet\s*werden\s*\?$/u, # 5
        'Schwanderschaft'     => /^Darf\s+\w+\s+W&auml;hrend\s+einer\s+Schwangerschaft\s+oder\s+in\s+der\s+Stillzeit\s+eingenommen\s*\/\s*angewendet\s*werden\s*\?$/u, # 7
        'Dos./Anw.'           => /^Wie\s+verwenden\s+Sie\s+\w+\s+\?$/u, # 8
        'Unerw.Wirkungen'     => /^Welche\s+Nebenwirklungen\s+kann\s+\w+\s+haben\s+\?$/u, # 9
        'Gew&ouml;hnliche H.' => /^Was\s+ist\s+ferner\s+zu\s+beachten\s*\?$/u, # 10
        'Zusammens.'          => /^Was\s+ist\s+in\s+\w+\s+enthalten\s*\?$/u, # 11
        'Swissmedic-Nr.'      => /^Zulassungsnummer$/u, # 12
        'Packungen'           => /^Wo\s+erhalten\s+Sie\s+\w+\s*\?\s*Welche\s+Packungen\s+sind\s+erh&auml;ltlich\s*\?$/u, # 13
        'Verteiler'           => /^Zulassungsinhaberin$/u, # 14
        'Hersteller'          => /^Herstellerin$/u, # 15
        'Stand d. Info.'      => /^Diese\sPackungsbeilage\s+wurde\s+im\s+\w+\s*\/\s*\w+\s+\(Monat\s*\/\s*Jahr\)\s*letztmals\s+durch\s+die\s+Alzneimittelbeh&ouml;rde\s+\(\s*Swissmedic\s*\)\s*gep&uuml;ft$/u, # 16
      }.each_pair do |chapter, regexp|
        if text =~ regexp
          next if !r.next.nil? and # skip matches in paragraph
                  r.next.name.downcase != 'bookmarkend'
          id = escape_as_id(text)
          @indecies << {:text => chapter, :id => id}
          return markup(:h3, text, {:id => id})
        end
      end
      if r.parent.previous.nil? and @indecies.empty?
        # The first line as package name
        @indecies << {:text => 'Titel', :id => 'titel'}
        return markup(:h2, text, {:id => 'titel'})
      end
      return nil
    end
  end
end
