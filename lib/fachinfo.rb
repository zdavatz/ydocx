#!/usr/bin/env ruby
# encoding: utf-8

require 'cgi'

module Docx2html
  class Parser
    attr_accessor :index
    def init
      @indecies = []
      @container = tag(:div, [], {:id => 'container'})
    end
    private
    def build_block(text)
      chapters = [
        /^Auslieferung|R.partiteur/u,
        /^Composition|^Principes\s*actifs/u,
        /^Dosierung\/Anwendung/u,
        /^Eigenschaften|^Propri.t.s/u,
        /^Estampille/u,
        /^Galenische\s*Form|^Forme\s*gal.nique/iu,
        /^Hersteller|^Fabricant/u,
        /^IKS-Nummern?|Num.ros? OICM/iu,
        /^Indikationen|^Indications/u,
        /^Interaktionen|^Interactions/u,
        /^Kontrainikationnen/u,
        /^Num.ro\s+d.autorisation/iu,
        /^Pr&auml;klinische\s+Daten/u,
        /^Pharmakokinetik?|Pharmacocin.tique?/iu,
        /^Principes\s*actifs/u,
        /^Sonstige|^Remarques/u,
        /^Schwanderschaft\/Stillzeit/u,
        /^Stand\s+der\s+Information|Mise\s+.\s+jour/iu,
        /^Unerw&uuml;nschte\s+Wirkungen/u,
        /^&Uuml;berdosierung|^Surdosage/u,
        /^Vertrieb|^Distributeur/u,
        /^Wahnhinweise\s+und\s+Vorsichsmassnahmen/u,
        /^Weitere\s+Angaben|Informations suppl.mentaires/iu,
        /^Wirkunf\s+auf\s+die\s+Fahrtüchtigkeit/u,
        /^Zulassungs(vermerk|nummer|inhaberin)/u, 
        /^Zusammensetzung/u,
        /^9\.11\.2001|^AMZV|^OEM.d/u,
      ].each do |chapter|
        if text =~ chapter
          id = CGI.escape(text.gsub(/&(.)uml;/, '\1').gsub(/\s|\//, '_').downcase)
          @indecies << {:text => text, :id => id}
          return tag(:h2, text, {:id => id})
        end
      end
      nil
    end
    def build_after_content
      link = tag(:a, 'Top', {:href => ''})
      tag(:div, link, {:id => 'footer'})
    end
    def build_before_content
      indices = []
      @indecies.each do |index|
        indices << tag(:li, tag(:a, index[:text], {:href => "#" + index[:id]}))
      end
      tag(:div, tag(:ul, indices), {:id => 'indecies'})
    end
  end
  class Builder
    def style
      style = <<-CSS
table, tr, td {
  border-collapse: collapse;
  border: 1px solid gray;
}
td {
  padding: 5px 10px;
}
html body {
  position: absolute;
}
div#indecies {
  position: relative;
  float:    left;
  width:    25%;
}
div#indecies ul {
  padding-left: 20px;
}
div#container {
  position: relative;
  float:    right;
  width:    75%;
}
div#footer {
  position:      relative;
  text-align:    right;
  float:         right;
  width:         100%;
  padding-right: 25px;
}
      CSS
      style.gsub(/\s\s+|\n/, ' ')
    end
  end
end
