#!/usr/bin/env ruby
# encoding: utf-8
require 'spec_helper'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

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

  it "should convert sinovial_FR to xml" do
    require 'ydocx/templates/fachinfo'
    sinovial_FR = File.join(YDcoxHelper::DataDir, 'Sinovial_FR.docx')
    File.exists?(sinovial_FR).should be true
    doc = YDocx::Document.open(sinovial_FR, { :lang => :fr})
    sinovial_FR_xml = sinovial_FR.sub('.docx', '.xml')
    doc.to_xml(sinovial_FR_xml, {:format => :fachinfo})
    out = doc.output_file('xml')    
    File.exists?(sinovial_FR_xml).should be true
    doc.parser.lang.to_s.should == 'fr'
    doc = Nokogiri::XML(open(sinovial_FR_xml))
    doc.xpath('//chapters/chapter[contains(heading, "Fabricant")]').size.should > 0
    doc.xpath('//chapters/chapter[contains(heading, "Distributeur")]').size.should > 0
    doc.xpath('//chapters/chapter[contains(heading, "Remarques particulières")]').size.should > 0
  end

  it "should convert sinovial_DE to xml" do
    sinovial_DE = File.join(YDcoxHelper::DataDir, 'Sinovial_DE.docx')
    File.exists?(sinovial_DE).should be true
    doc = YDocx::Document.open(sinovial_DE)
    sinovial_DE_xml = sinovial_DE.sub('.docx', '.xml')
    doc.to_xml(sinovial_DE_xml, {:format => :fachinfo})
    out = doc.output_file('xml')
    File.exists?(sinovial_DE_xml).should be true
    doc.parser.lang.to_s.should == 'de'
    doc = Nokogiri::XML(open(sinovial_DE_xml))
    doc.xpath('//chapters/chapter[contains(heading, "Packung")]').size.should > 0
    doc.xpath('//chapters/chapter[contains(heading, "Hersteller")]').size.should > 0
    doc.xpath('//chapters/chapter[contains(heading, "Vertriebsfirma")]').size.should > 0
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
            require 'ydocx/templates/fachinfo'
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
        doc = Nokogiri::XML(open(file_name_xml))
    }
  end
end
