require_relative 'lib/ydocx/version'

spec = Gem::Specification.new do |s|
   s.name        = "ydocx"
   s.version     =  YDocx::VERSION
   s.summary     = "Parsing docx files with Ruby and output them as HTML and XML"
   s.description = ""
   s.author      = "'Yasuhiro Asak, Zeno R.R. Davatz"
   s.email       = "yasaka@ywesee.com, zdavatz@ywesee.com"
   s.platform    = Gem::Platform::RUBY
   s.license     = "GPLv3"
   s.files       = Dir.glob("{bin,lib,spec}/**/*") + Dir.glob("*.txt")
   s.executables << "docx2xml"
   s.executables << "docx2html"
   s.homepage	 = "https://github.com/zdavatz/ydocx/"
end

