#!/usr/bin/env ruby
# encoding: utf-8
require 'spec_helper'

describe "ydocx" do
 
  before :all do
  end
  
  before :each do
    Dir.glob("#{YDcoxHelper::DataDir}/*.xml").each { |file| FileUtils.rm_f(file, :verbose => $VERBOSE) }
    Dir.glob("#{YDcoxHelper::DataDir}/*.html").each { |file| FileUtils.rm_f(file, :verbose => $VERBOSE) }
  end
  
  after :each do
  end
  
  after :all do
    Dir.glob("#{YDcoxHelper::DataDir}/*.xml").each { |file| FileUtils.rm_f(file, :verbose => $VERBOSE) }
    Dir.glob("#{YDcoxHelper::DataDir}/*.html").each { |file| FileUtils.rm_f(file, :verbose => $VERBOSE) }
  end

  it "should convert sinovial_DE to xml" do
    sinovial_DE = File.join(YDcoxHelper::DataDir, 'Sinovial_DE.docx')
    File.exists?(sinovial_DE).should be true
    doc = YDocx::Document.open(sinovial_DE)
    sinovial_DE_xml = sinovial_DE.sub('.docx', '.xml')
    doc.to_xml(sinovial_DE_xml, {:format => :fachinfo})
    out = doc.output_file('xml')
    File.exists?(sinovial_DE_xml).should be true
  end

  it "should convert sinovial_DE to html" do
    sinovial_DE = File.join(YDcoxHelper::DataDir, 'Sinovial_DE.docx')
    File.exists?(sinovial_DE).should be true
    doc = YDocx::Document.open(sinovial_DE)
    sinovial_DE_html = sinovial_DE.sub('.docx', '.html')
    doc.to_html(sinovial_DE_html, {:format => :fachinfo})
    out = doc.output_file('html')
    File.exists?(sinovial_DE_html).should be true
  end

  it "should convert various pseudo fachinfo to xml" do
    files = [ 'Sinovial_0.8_DE.docx', 'Sinovial_0.8_FR.docx',
              'Sinovial_DE.docx',     'Sinovial_FR.docx',
            ]
    files.each {
      |file|
        file_name = File.join(YDcoxHelper::DataDir, file)
        File.exists?(file_name).should be true
        file.match('_DE') ? lang = 'de' : lang = 'fr'
        doc = YDocx::Document.open(file_name, { :lang => lang} )
        file_name_xml = file_name.sub('.docx', '.xml')
        doc.to_xml(file_name_xml, {:format => :fachinfo})
        out = doc.output_file('xml')
        File.exists?(file_name_xml).should be true
        doc.parser.lang.should == lang
    }
  end

end

test = %(
doc = Nokogiri::XML(open('/opt/src/ydocx/spec/data/Sinovial_DE.xml'))
 doc.xpath('//chapters/paragraph').text
 => "\n      Sinovial\n      ® \n      HighVisc\n       1,6%\n
 doc.xpath('//chapters/chapter').each{ |x| next if x.xpath('heading').size == 0; puts "\n\n"+x.xpath('heading').text; puts x.xpath('paragraph').text}

 doc.xpath('//chapters/chapter').each{ |x| next unless x.xpath('heading').text.match(/Packungen/); x.xpath('paragraph').each{ |p| puts p.text} }
ean13 = [] ; doc.xpath('//chapters/chapter').each{ |x| next unless x.xpath('heading').text.match(/Packungen/); x.xpath('paragraph').each{
	|p| m= p.text.match(/(\d{13})($|\s|\W)/); ean13 << m[1] if m } }; ean13

)
