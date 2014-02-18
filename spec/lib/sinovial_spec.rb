#!/usr/bin/env ruby
# encoding: utf-8
require 'spec_helper'

@workThread = nil

describe "ch.oddb.org" do
 
  before :all do
  end
  
  before :each do
  end
  
  after :each do
  end
  
  it "should convert sinovial_DE to xml" do
		sinovial_DE = File.join(@@data_dir, 'Sinovial_DE.docx')
		File.exists?(sinovial_DE).should be true
		doc = YDocx::Document.open(sinovial_DE)
		sinovial_DE_xml = sinovial_DE.sub('.docx', '.xml')
		doc.to_xml(sinovial_DE_xml, {})
		out = doc.output_file('xml')
		File.exists?(sinovial_DE_xml).should be true
  end

  it "should convert sinovial_DE to html" do
		sinovial_DE = File.join(@@data_dir, 'Sinovial_DE.docx')
		File.exists?(sinovial_DE).should be true
		doc = YDocx::Document.open(sinovial_DE)
		sinovial_DE_html = sinovial_DE.sub('.docx', '.html')
		doc.to_html(sinovial_DE_html, {})
		out = doc.output_file('html')
		File.exists?(sinovial_DE_html).should be true
  end

  after :all do
  end 
end
