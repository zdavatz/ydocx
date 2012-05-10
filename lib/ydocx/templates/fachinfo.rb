#!/usr/bin/env ruby
# encoding: utf-8

require 'cgi'

module YDocx
  class Parser
    attr_reader :code
    def init
      @image_path = 'image'
      @code = nil
    end
    private
    def chapters
      # TODO
      # Franzoesisch
      chapters = {
        'Name'                => /^Name\s+des\s+Pr&auml;parates$/u, # 1
        'Zusammens.'          => /^Zusammensetzung($|\s*\/\s*(Wirkstoffe|Hilsstoffe)$)/u, # 2
        'Galen.Form'          => /^Galenische\s+Form\s*(und|\/)\s*Wirkstoffmenge\s+pro\s+Einheit$|^Forme\s*gal.nique/iu, # 3
        'Ind./Anw.m&ouml;gl.' => /^Indikationen(\s+|\s*(\/|und)\s*)Anwendungsm&ouml;glichkeiten$|^Indications/u, # 4
        'Dos./Anw.'           => /^Dosierung\s*(\/|und)\s*Anwendung/u, # 5
        'Kontraind.'          => /^Kontraindikationen($|\s*\(\s*absolute\s+Kontraindikationen\s*\)$)/u, # 6
        'Warn.hinw.'          => /^Warnhinweise\s+und\s+Vorsichtsmassnahmen($|\s*\/\s*(relative\s+Kontraindikationen|Warnhinweise\s*und\s*Vorsichtsmassnahmen)$)/u, # 7
        'Interakt.'           => /^Interaktionen$|^Interactions/u, # 8
        'Schwangerschaft'     => /^Schwangerschaft(,\s*|\s*\/\s*|\s+und\s+)Stillzeit$/u, # 9
        'Fahrt&uuml;cht.'     => /^Wirkung\s+auf\s+die\s+Fahrt&uuml;chtigkeit\s+und\s+auf\s+das\s+Bedienen\s+von\s+Maschinen$/u, # 10
        'Unerw.Wirkungen'     => /^Unerw&uuml;nschte\s+Wirkungen$/u, # 11
        '&Uuml;berdos.'       => /^&Uuml;berdosierung$|^Surdosage$/u, # 12
        'Eigensch.'           => /^Eigenschaften\s*\/\s*Wirkungen($|\s*\(\s*(ATC\-Code|Wirkungsmechanismus|Pharmakodyamik|Klinische\s+Wirksamkeit)\s*\)\s*$)|^Propri.t.s/iu, # 13
        'Pharm.kinetik'       => /^Pharmakokinetik($|\s*\((Absorption,\s*Distribution,\s*Metabolisms,\s*Elimination\s|Kinetik\s+spezieller\s+Patientengruppen)*\)$)|^Pharmacocin.tique?/iu, # 14
        'Pr&auml;klin.'       => /^Pr&auml;klinische\s+Daten$/u, # 15
        'Sonstige H.'         => /^Sonstige\s*Hinweise($|\s*\(\s*(Inkompatibilit&auml;ten|Beeinflussung\s*diagnostischer\s*Methoden|Haltbarkeit|Besondere\s*Lagerungshinweise|Hinweise\s+f&uuml;r\s+die\s+Handhabung)\s*\)$)|^Remarques/u, # 16
        'Swissmedic-Nr.'      => /^Zulassungsnummer(:|$|\s*\(\s*Swissmedic\s*\)$)/u, # 17
        'Packungen'           => /^Packungen($|\s*\(\s*mit\s+Angabe\s+der\s+Abgabekategorie\s*\)$)/u, # 18
        'Reg.Inhaber'         => /^Zulassungsinhaberin($|\s*\(\s*Firma\s+und\s+Sitz\s+gem&auml;ss\s*Handelsregisterauszug\s*\))/u, # 19
        'Stand d. Info.'      => /^Stand\s+der\s+Information$|^Mise\s+.\s+jour$/iu, # 20
      }
    end
    def escape_id(text)
      CGI.escape(text.gsub(/&(.)uml;/, '\1e').gsub(/\s*\/\s*|\s+|\/|\-/, '_').gsub(/\./, '').downcase)
    end
    def parse_code(text)
      if text =~ /^\s*(\d\d)(&lsquo;|&rsquo;|&apos;|.|\s*)(\d\d\d)\s*\(\s*Swiss\s*medic\s*\)(\s*|.)$/iu
        @code = "%5d" % ($1 + $3)
      else
        nil
      end
    end
    def parse_block(node)
      text = node.inner_text.strip
      text = optional_escape text
      chapters.each_pair do |chapter, regexp|
        if text =~ regexp
          # allow without line break
          # next if !node.previous.inner_text.empty? and !node.next.inner_text.empty?
          id = escape_id(chapter)
          @indecies << {:text => chapter, :id => id}
          return markup(:h3, text, {:id => id})
        elsif parse_code(text)
          return nil
        end
      end
      if @indecies.empty? and !text.empty? and node.parent.previous.nil?
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
        markup(:div, markup(:ol, indices), {:id => 'indecies'})
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
  width:    215px;
}
div#indecies ol {
  margin:  0;
  padding: 25px 0 0 40px;
}
div#container {
  position: relative;
  padding:  5px;
  float:    top left;
  margin:   0 0 0 215px;
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
  padding:  0 0 0 5px;
  height:   100%;
  left:     0;
  top:      0;
}
div#container {
  position: absolute;
  padding:  0 20px 0 5px;
  height:   100%;
  overflow: auto;
}
        FRAME
      end
      style.gsub(/\s\s+|\n/, ' ')
    end
    def resolve_path(path)
      path
    end
  end
  # == Document
  # Image reference option
  # Currently, this supports only all images or first one reference.
  # 
  # $ docx2html example.docx --format fachinfo refence1.png refenece2.png
  class Document
    def init
      @directory = 'fi'
      @references = []
      prepare_reference
    end
    def output_directory
      unless @files
        if @parser.code
          @files = Pathname.new(@directory + '/' + @parser.code)
        else
          @files = @path.dirname.join(@path.basename('.docx').to_s + '_files')
        end
      end
      @files
    end
    def output_file(ext)
      if @parser.code
        filename = @parser.code
        output_directory.join "#{filename}.#{ext.to_s}"
      else # default
        @path.sub_ext(".#{ext.to_s}")
      end
    end
    private
    def has_image?
      # TODO
      # fi/pi format needs always directories.
      # now returns just true
      true
    end
    alias :copy_or_convert :organize_image
    def organize_image(origin_path, source_path)
      if reference = @references.shift and
         File.extname(reference) == source_path.extname
        FileUtils.copy reference, @files.join(source_path)
      else
        copy_or_convert(origin_path, source_path)
      end
    end
    def prepare_reference
      ARGV.reverse.each do |arg|
        if arg.downcase =~ /\.(jpeg|jpg|png|gif)$/
          path = Pathname.new(arg).realpath
          @references << path if path.exist?
        end
      end
      @references.reverse unless @references.empty?
    end
  end
end
