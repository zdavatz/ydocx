#!/usr/bin/env ruby
# encoding: utf-8

require 'cgi'

module YDocx
  class Parser
    private
    def parse_as_block(r, text)
      text = text.strip
      # TODO
      # Franzoesisch
      chapters = {
        'Dos./Anw.'           => /^Dosierung\s*(\/|und)\s*Anwendung/u, # 5
        'Eigensch.'           => /^Eigenschaften\s*\/\s*Wirkungen($|\s*\(\s*(ATC\-Code|Wirkungsmechanismus|Pharmakodyamik|Klinische\s+Wirksamkeit)\s*\)\s*$)|^Propri.t.s/iu, # 13
        'Galen.Form'          => /^Galenische\s+Form\s*(und|\/)\s*Wirkstoffmenge\s+pro\s+Einheit$|^Forme\s*gal.nique/iu, # 3
        'Ind./Anw.m&ouml;gl.' => /^Indikationen(\s+|\s*(\/|und)\s*)Anwendungsm&ouml;glichkeiten$|^Indications/u, # 4
        'Interakt.'           => /^Interaktionen$|^Interactions/u, # 8
        'Kontraind.'          => /^Kontraindikationen($|\s*\(\s*absolute\s+Kontraindikationen\s*\)$)/u, # 6
        'Name'                => /^Name\s+des\s+Pr&auml;parates$/, # 1
        'Packungen'           => /^Packungen($|\s*\(\s*mit\s+Angabe\s+der\s+Abgabekategorie\s*\)$)/u, # 18
        'Pr&auml;klin.'       => /^Pr&auml;klinische\s+Daten$/u, # 15
        'Pharm.kinetik'       => /^Pharmakokinetik($|\s*\((Absorption,\s*Distribution,\s*Metabolisms,\s*Elimination\s|Kinetik\s+spezieller\s+Patientengruppen)*\)$)|^Pharmacocin.tique?/iu, # 14
        'Sonstige H.'         => /^Sonstige\s*Hinweise($|\s*\(\s*(Inkompatibilit&auml;ten|Beeinflussung\s*diagnostischer\s*Methoden|Haltbarkeit|Besondere\s*Lagerungshinweise|Hinweise\s+f&uuml;r\s+die\s+Handhabung)\s*\)$)|^Remarques/u, # 16
        'Schwangerschaft'     => /^Schwangerschaft(,\s*|\s*\/\s*|\s+und\s+)Stillzeit$/u, # 9
        'Stand d. Info.'      => /^Stand\s+der\s+Information$|^Mise\s+.\s+jour$/iu, # 20
        'Unerw.Wirkungen'     => /^Unerw&uuml;nschte\s+Wirkungen$/u, # 11
        '&Uuml;berdos.'       => /^&Uuml;berdosierung$|^Surdosage$/u, # 12
        'Warn.hinw.'          => /^Warnhinweise\s+und\s+Vorsichtsmassnahmen($|\s*\/\s*(relative\s+Kontraindikationen|Warnhinweise\s*und\s*Vorsichtsmassnahmen)$)/u, # 7
        'Fahrt&uuml;cht.'     => /^Wirkung\s+auf\s+die\s+Fahrt&uuml;chtigkeit\s+und\s+auf\s+das\s+Bedienen\s+von\s+Maschinen$/u, # 10
        'Swissmedic-Nr.'      => /^Zulassungsnummer($|\s*\(\s*Swissmedic\s*\)$)/u, # 17
        'Reg.Inhaber'         => /^Zulassungsinhaberin($|\s*\(\s*Firma\s+und\s+Sitz\s+gem&auml;ss\s*Handelsregisterauszug\s*\))/u, # 19
        'Zusammens.'          => /^Zusammensetzung($|\s*\/\s*(Wirkstoffe|Hilsstoffe)$)/u, # 2
      }.each_pair do |chapter, regexp|
        if text =~ regexp
          next if !r.next.nil? and # skip matches in paragraph
                  r.next.name.downcase != 'bookmarkend'
          id = CGI.escape(text.gsub(/&(.)uml;/, '\1').gsub(/\s*\/\s*|\/|\s+/, '_').downcase)
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
  class Builder
    def init
      @container = markup(:div, [], {:id => 'container'})
    end
    def build_xml
      chapters = compile(@contents, :xml)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.document {
          xml.chapters { xml << chapters }
        }
      end
      builder.to_xml(:indent => 0, :encoding => 'utf-8').gsub(/\n/, '')
    end
    private
    def build_before_content
      if @indecies
        indices = []
        @indecies.each do |index|
          if index.has_key?(:id)
            link = markup(:a, index[:text], {:href => "#" + index[:id]})
            indices << markup(:li, link)
          end
        end
        markup(:div, markup(:ul, indices), {:id => 'indecies'})
      end
    end
    def style
      style = <<-CSS
table, tr, td {
  border-collapse: collapse;
  border:          1px solid gray;
}
table {
  margin: 5px 0 5px 0;
}
td {
  padding: 5px 10px;
}
body {
  position: relative;
  padding:  0 0 25px 0;
  margin:   0px;
  width:    100%;
  height:   auto;
}
div#indecies {
  position: relative;
  padding:  0px;
  margin:   0px;
  float:    left;
  width:    200px;
}
div#indecies ul {
  margin:  0;
  padding: 25px 0 0 25px;
}
div#container {
  position: relative;
  padding:  5px 0 0 0;
  float:    top left;
  margin:   0 0 0 200px;
}
      CSS
      if @style == :frame
        style << <<-FRAME
html {
  overflow: hidden;
  height:   100%;
  width:    100%;
}
body{
  position: absolute;
  overflow: hidden;
  padding:  0;
  height:   100%;
  width:    100%;
}
div#indecies {
  position: absolute;
  padding:  0;
  height:   100%;
  left:     0;
  top:      0;
}
div#container {
  position: absolute;
  padding:  0;
  height:   100%;
  overflow: auto;
}
        FRAME
      end
      style.gsub(/\s\s+|\n/, ' ')
    end
  end
end
