#!/usr/bin/env ruby
# encoding: utf-8

require 'cgi'

module YDocx
  class Parser
    attr_accessor :code, :lang
    @@figure_pattern = /&lsquo;|&rsquo;|&apos;|&acute;/
    def init
      @image_path = 'image'
      @code = nil
      @lang ||= 'de'
    end
    private
    ###
    # Fachinfo Chapters
    #  1. name
    #  2. composition
    #  3. galenic form
    #  4. indications
    #  5. usage
    #  6. contra_indications
    #  7. restrictions
    #  8. interactions
    #  9. pregnancy
    # 10. driving_ability
    # 11. unwanted_effects
    # 12. overdose
    # 13. effects
    # 14. kinetic
    # 15. preclinic
    # 16. other_advice
    # 17. iksnr
    # 19. packages
    # 19. registration_owner
    # 20. date
    def chapters
      chapters = {
        :de => {
          "Name"                => /^Name\s+des\s+Pr&auml;parates$/u, # 1
          "Zusammens."          => /^Zusammensetzung($|\s*\/\s*(Wirkstoffe|Hilsstoffe)$)/u, # 2
          "Galen.Form"          => /^Galenische\s+Form\s*(und|\/)\s*Wirkstoffmenge\s+pro\s+Einheit$/iu, # 3
          "Ind./Anw.m&ouml;gl." => /^Indikationen(\s+|\s*(\/|und)\s*)Anwendungsm&ouml;glichkeiten$/u, # 4
          "Dos./Anw."           => /^Dosierung\s*(\/|und)\s*Anwendung/u, # 5
          "Kontraind."          => /^Kontraindikationen($|\s*\(\s*absolute\s+Kontraindikationen\s*\)$)/u, # 6
          "Warn.hinw."          => /^Warnhinweise\s+und\s+Vorsichtsmassnahmen($|\s*\/\s*(relative\s+Kontraindikationen|Warnhinweise\s*und\s*Vorsichtsmassnahmen)$)/u, # 7
          "Interakt."           => /^Interaktionen$/u, # 8
          "Schwangerschaft"     => /^Schwangerschaft(,\s*|\s*\/\s*|\s+und\s+)Stillzeit$/u, # 9
          "Fahrt&uuml;cht."     => /^Wirkung\s+auf\s+die\s+Fahrt&uuml;chtigkeit\s+und\s+auf\s+das\s+Bedienen\s+von\s+Maschinen$/u, # 10
          "Unerw.Wirkungen"     => /^Unerw&uuml;nschte\s+Wirkungen$/u, # 11
          "&Uuml;berdos."       => /^&Uuml;berdosierung$/u, # 12
          "Eigensch."           => /^Eigenschaften\s*\/\s*Wirkungen($|\s*\(\s*(ATC\-Code|Wirkungsmechanismus|Pharmakodyamik|Klinische\s+Wirksamkeit)\s*\)\s*$)/iu, # 13
          "Pharm.kinetik"       => /^Pharmakokinetik($|\s*\((Absorption,\s*Distribution,\s*Metabolisms,\s*Elimination\s|Kinetik\s+spezieller\s+Patientengruppen)*\)$)/iu, # 14
          "Pr&auml;klin."       => /^Pr&auml;klinische\s+Daten$/u, # 15
          "Sonstige H."         => /^Sonstige\s*Hinweise($|\s*\(\s*(Inkompatibilit&auml;ten|Beeinflussung\s*diagnostischer\s*Methoden|Haltbarkeit|Besondere\s*Lagerungshinweise|Hinweise\s+f&uuml;r\s+die\s+Handhabung)\s*\)$)|^Remarques/u, # 16
          "Swissmedic-Nr."      => /^Zulassungsnummer(n|:|$|\s*\(\s*Swissmedic\s*\)$)/u, # 17
          "Packungen"           => /^Packungen($|\s*\(\s*mit\s+Angabe\s+der\s+Abgabekategorie\s*\)$)/u, # 18
          "Reg.Inhaber"         => /^Zulassungsinhaberin($|\s*\(\s*Firma\s+und\s+Sitz\s+gem&auml;ss\s*Handelsregisterauszug\s*\))/u, # 19
          "Stand d. Info."      => /^Stand\s+der\s+Information$/iu, # 20
        },
        :fr => {
          "Nom"                    => /^Nom$/u, # 1
          "Composit."              => /^Composition$/u, # 2
          "Forme gal."             => /^Forme\s+gal&eacute;nique\s+et\s+quantit&eacute;\s+de\s+principe\s+actif\s+par\s+unit&eacute;|^Forme\s*gal.nique/iu, # 3
          "Indic./emploi"          => /^Indications\s*\/\s*Possibilit&eacute;s\s+d&apos;emploi/u, # 4
          "Posolog./mode d&apos;empl." => /^Posologie\s*\/\s*Mode\s+d&apos;emploi/u, # 5
          "Contre-Ind."            => /^Contre\-indications$/iu, # 6
          "Pr&eacute;cautions"     => /^Mises\s+en\s+garde\s+et\s+pr&eacute;cautions/u, # 7
          "Interact."              => /^Interactions$/u, # 8
          "Grossesse"              => /^Grossesse\s*\/\s*Allaitement/u, # 9
          "Apt.conduite"           => /^Effet\s+sur\s+l&apos;aptitude\s+&agrave;\s+la\s+conduite\s+et\s+l&apos;utilisation\s+de\s+machines/u, # 10
          "Effets ind&eacute;sir." => /^Effets\s+ind&eacute;sirables$/u, # 11
          "Surdosage"              => /^Surdosage$/u, # 12
          "Propri&eacute;t&eacute;s" => /^Propri&eacute;t&eacute;s\s*\/\s*Effets$/iu, # 13
          "Pharm.cin&eacute;t."    => /^Pharmacocin&eacute;tique$/iu, # 14
          "Donn.pr&eacute;cl."     => /^Donn&eacute;es\s+pr&eacute;cliniques$/u, # 15
          "Remarques"              => /^Remarques\s+particuli&egrave;res$/u, # 16
          "Estampille"             => /^Num&eacute;ro\s+d&apos;autorisation$/u, # 17
          "Pr&eacute;sentations"   => /^Pr&eacute;sentation$/u, # 18
          "Titulaire"              => /^Titulaire\s+de\s+l&apos;autorisation$/u, # 19
          "Mise &agrave; jour"     => /^Mise\s+.\s+jour$|^Etat\s+de\s+l&apos;information/iu, # 20
        }
      }
      if @lang == 'fr'
        chapters[:fr]
      else
        chapters[:de]
      end
    end
    def escape_id(text)
      CGI.escape(text.
                 gsub(/&(.)uml;/, '\1e').gsub(/&apos;/, '').gsub(/&(eacute|agrave);/, 'e').
                 gsub(/\s*\/\s*|\s+|\/|\-/, '_').gsub(/\./, '').downcase)
    end
    def parse_code(text) # swissmedic number
      if text.gsub(@@figure_pattern, '') =~
         /^\s*(\d{5})(.*|\s*)\s*\(\s*Swiss\s*medic\s*\)(\s*|.)$/iu
        @code = "%5d" % $1
      else
        nil
      end
    end
    def parse_heading(text, id)
      return markup(:h2, text, {:id => id})
    end
    def parse_title(node, text)
      if @indecies.empty? and !text.empty? and node.previous and
         (node.previous.inner_text.strip.empty? or node.parent.previous.nil?)
        # The first line as package name
        title = (@lang == 'fr' ? 'Titre' : 'Titel')
        @indecies << {:text => title, :id => title.downcase}
        return markup(:h1, text, {:id => title.downcase})
      else
        return nil
      end
    end
    def parse_block(node)
      text = node.inner_text.strip
      text = character_encode(text)
      chapters.each_pair do |chapter, regexp|
        if text =~ regexp
          # allow without line break
          # next if !node.previous.inner_text.empty? and !node.next.inner_text.empty?
          id = escape_id(chapter)
          @indecies << {:text => chapter, :id => id}
          return parse_heading(text, id)
        end
      end
      if title = parse_title(node, text)
        return title
      end
      parse_code(text)
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
    def resolve_path(path) # image src
      if reference = @references.shift
        File.dirname(path) + '/' + reference.basename.to_s
      elsif @files.to_s =~ /\d{5}/
        path
      else
        @files.join path
      end
    end
  end
  class Document
    def init
      @directory = 'fi'
      @references = []
      prepare_reference
    end
    def output_directory
      unless @files
        if @parser.code
          files = @directory + '/' + @parser.code
        else
          files = @path.basename('.docx').to_s + '_files'
        end
        @files = @path.dirname.join files
      end
      @files
    end
    def output_file(ext) # html
      lang = (@parser.lang.downcase == 'fr' ? 'fr' : 'de')
      if @parser.code
        filename = @parser.code
        output_directory.join "#{lang}_#{filename}.#{ext.to_s}"
      else # default
        @path.sub_ext(".#{ext.to_s}")
      end
    end
    private
    def has_image?
      # NOTE
      # fi/pi format needs always directories.
      # now returns just true
      true
    end
    def optional_copy(source_path)
    end
    # NOTE
    # Image reference option
    # Currently, this supports only all images or first one reference.
    #
    # $ docx2html example.docx --format fachinfo refence1.png refenece2.png
    alias :copy_or_convert :organize_image
    def organize_image(origin_path, source_path)
      if reference = @references.shift
        new_source_path = source_path.dirname.to_s + '/' + File.basename(reference)
        if reference != @files.join(new_source_path).realpath # same file
          FileUtils.copy reference, @files.join(new_source_path)
        end
      else
        copy_or_convert(origin_path, source_path)
      end
      optional_copy(source_path)
    end
    def prepare_reference
      ARGV.reverse.each do |arg|
        if arg.downcase =~ /\.(jpeg|jpg|png|gif)$/
          path = Pathname.new(arg)
          @references << path.realpath if path.exist?
        end
      end
      @references.reverse unless @references.empty?
    end
  end
end
