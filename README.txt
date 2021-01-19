== ydocx by ywesee GmbH

* https://github.com/zdavatz/ydocx
* Parsing docx files with Ruby and output them as HTML and XML.

== Supports

* Tables
* Uppercase letters, numbers
* Lowercase letters, numbers
* Umlaute
* bold, italic, underline
* Images 
 ** wmf requires imagemagick and is only partially supported due to imagemagick
 ** png files are copied 1:1

* works on Windows as well.

== Usage

* Usage: docx2html file [options]
    -f, --format    Format of style and chapter {(fi|fachinfo)|(pi|patinfo)|(pl|plain)|none}, default fachinfo.
    -h, --help      Display this help message.
    -l, --lang      Language option for templates {de|fr}
    -v, --version   Show version.

== Using the great libraries

* rubyzip (< 1.0.0)
* nokogiri
* htmlentities
* rmagick

Install them using bundle install.

Requires Ruby >= 1.9.2.

== TODO

For unknown reason the gem fails to  parse properly the Présentation for sinovial_fr.
Failing spec is: ydocx should convert sinovial_FR to xml
     Failure/Error: doc.xpath('//chapters/chapter[contains(heading, "Présentation")]').size.should > 0
     

== License GPLv3.0

* http://www.gnu.org/licenses/gpl.html
