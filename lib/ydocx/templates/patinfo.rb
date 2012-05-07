#!/usr/bin/env ruby
# encoding: utf-8

require 'ydocx/templates/fachinfo'

module YDocx
  class Parser
    def init
      @image_path = 'pi_images'
    end
    private
    def parse_block(node)
      text = node.inner_text.strip
      text = optional_escape text
      # TODO
      # Franzoesisch
      chapters = {
        'Information'         => /^Information\s+f&uuml;r\sPatientinnen\s+und\s+Patienten$/u, # 1
        'Name'                => /^Name\s+des\s+Pr&auml;parates$/u, # 2
        'Eigensch.'           => /^Was\s+ist\s+\w+\s+und\s+wann\s+wird\s+es\s+angewendet\s*\??$/u, # 3
        'Ab&auml;nderung'     => /^Was\s+sollte\s+dazu\s+beachtet\s+werden\s*\??$/u, # 4
        'Kontraind.'          => /^Wann\s+darf\s+\w+\s+nicht\s+(eingenommen\s*\/\s*angewendet|eingenommen|angewendet)\s*werden\s*\??$/u, # 5
        'Vorbeugung'          => /^Wann\s+ist\s+bei\s+der\s+(Einnahme\s*\/\s*Anwendung|Einnahme|Anwendung)\s*von\s+\w+\s+Vorsicht\s+geboten\s*\??$/u, # 6
        'Schwanderschaft'     => /^Darf\s+\w+\s+w&auml;hrend\s+einer\s+Schwangerschaft\s+oder\s+in\s+der\s+Stillzeit\s+(eingenommen\s*\/\s*angewendet|eingenommen|angewendet)\s*werden\s*\??$/u, # 7
        'Dos./Anw.'           => /^Wie\s+verwenden\s+Sie\s+\w+\s*\??$/u, # 8
        'Unerw.Wirkungen'     => /^Welche\s+Nebenwirkungen\s+kann\s+\w+\s+haben\s*\??$/u, # 9
        'Gew&ouml;hnliche H.' => /^Was\s+ist\s+ferner\s+zu\s+beachten\s*\??$/u, # 10
        'Zusammens.'          => /^Was\s+ist\s+in\s+\w+\s+enthalten\s*\??$/u, # 11
        'Swissmedic-Nr.'      => /^Zulassungsnummer$/u, # 12
        'Packungen'           => /^Wo\s+erhalten\s+Sie\s+\w+\s*\?\s*Welche\s+Packungen\s+sind\s+erh&auml;ltlich\s*\??$/u, # 13
        'Verteiler'           => /^Zulassungsinhaberin$/u, # 14
        'Hersteller'          => /^Herstellerin$/u, # 15
        'Stand d. Info.'      => /^Diese\sPackungsbeilage\s+wurde\s+im\s+[\.A-z\s0-9]+(\s+|\s*\/\s*\w+\s+\(Monat\s*\/\s*Jahr\)\s*)letztmals\s+durch\s+die\s+Arzneimittelbeh&ouml;rde\s*\(\s*Swissmedic\s*\)\s*gepr&uuml;ft.?$/u, # 16
      }.each_pair do |chapter, regexp|
        if text =~ regexp
          # allow without line break
          #next if !node.previous.inner_text.empty? and !node.next.inner_text.empty?
          id = escape_id(chapter)
          @indecies << {:text => chapter, :id => id}
          return markup(:h3, text, {:id => id})
        end
      end
      if node.parent.previous.nil? and @indecies.empty?
        # The first line as package name
        @indecies << {:text => 'Titel', :id => 'titel'}
        return markup(:h2, text, {:id => 'titel'})
      end
      return nil
    end
  end
end
