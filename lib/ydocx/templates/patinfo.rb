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
        'Ab&auml;nderung'     => /^Was\s+sollte\s+dazu\s+beachtet\s+werden\s*\??$/u, # 4
        'Dos./Anw.'           => /^Wie\s+verwenden\s+Sie\s+\w+\s*\??$/u, # 8
        'Eigensch.'           => /^Was\s+ist\s+\w+\s+und\s+wann\s+wird\s+es\s+angewendet\s*\??$/u, # 3
        'Gew&ouml;hnliche H.' => /^Was\s+ist\s+ferner\s+zu\s+beachten\s*\??$/u, # 10
        'Hersteller'          => /^Herstellerin$/u, # 15
        'Information'         => /^Information\s+f&uuml;r\sPatientinnen\s+und\s+Patienten$/u, # 1
        'Kontraind.'          => /^Wann\s+darf\s+\w+\s+nicht\s+(eingenommen\s*\/\s*angewendet|eingenommen|angewendet)\s*werden\s*\??$/u, # 5
        'Name'                => /^Name\s+des\s+Pr&auml;parates$/u, # 2
        'Packungen'           => /^Wo\s+erhalten\s+Sie\s+\w+\s*\?\s*Welche\s+Packungen\s+sind\s+erh&auml;ltlich\s*\??$/u, # 13
        'Schwanderschaft'     => /^Darf\s+\w+\s+w&auml;hrend\s+einer\s+Schwangerschaft\s+oder\s+in\s+der\s+Stillzeit\s+(eingenommen\s*\/\s*angewendet|eingenommen|angewendet)\s*werden\s*\??$/u, # 7
        'Stand d. Info.'      => /^Diese\sPackungsbeilage\s+wurde\s+im\s+[\.A-z\s0-9]+(\s+|\s*\/\s*\w+\s+\(Monat\s*\/\s*Jahr\)\s*)letztmals\s+durch\s+die\s+Arzneimittelbeh&ouml;rde\s*\(\s*Swissmedic\s*\)\s*gepr&uuml;ft.?$/u, # 16
        'Swissmedic-Nr.'      => /^Zulassungsnummer$/u, # 12
        'Unerw.Wirkungen'     => /^Welche\s+Nebenwirkungen\s+kann\s+\w+\s+haben\s*\??$/u, # 9
        'Verteiler'           => /^Zulassungsinhaberin$/u, # 14
        'Vorbeugung'          => /^Wann\s+ist\s+bei\s+der\s+(Einnahme\s*\/\s*Anwendung|Einnahme|Anwendung)\s*von\s+\w+\s+Vorsicht\s+geboten\s*\??$/u, # 6
        'Zusammens.'          => /^Was\s+ist\s+in\s+\w+\s+enthalten\s*\??$/u, # 11
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
