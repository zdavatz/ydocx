#!/usr/bin/env ruby
# encoding: utf-8

require 'ydocx'

module YDocx
  class Command
    class << self
      @@format  = /^\-(f|\-format)$/u
      @@help    = /^\-(h|\-help)$/u
      @@lang    = /^\-(l|\-lang)$/u
      @@version = /^\-(v|\-version)$/u
      def error(message='')
        puts message
        puts "see `#{self.command} --help`"
        exit
      end
      def extname(action)
        action == :to_html ? '.html': '.xml'
      end
      def command
        File.basename $0
      end
      def help
        banner = <<-BANNER
Usage: #{self.command} file [options]
  -f, --format    Format of style and chapter {(fi|fachinfo)|(pi|patinfo)|(pl|plain)|none}, default fachinfo.
  -h, --help      Display this help message.
  -l, --lang      Language option for templates {de|fr}
  -v, --version   Show version.
        BANNER
        puts banner
        exit
      end
      def parse(action, argv)
        if argv.length.odd?
          self.error "#{self.command}: exit with: Invalid option"
        else
          args = Hash[*argv]
        end
        options = {}
        args.each_pair do |option, value|
          if option =~ @@format
            case value
            when 'fi', 'fachinfo'
              require 'ydocx/templates/fachinfo'
              options.merge!({:style => :frame}) if action == :to_html
            when 'pi', 'patinfo'
              require 'ydocx/templates/patinfo'
              options.merge!({:style => :frame}) if action == :to_html
            when 'pl', 'plain'
              options.merge!({:style => true}) if action == :to_html
            when 'none'
              # pass
            else
              self.error "#{self.command}: exit with #{option}: Invalid argument"
            end
          elsif option =~ @@help
            self.help
          elsif option =~ @@lang
            options.merge!({:lang => value})
          elsif option.downcase =~ /\.(jpeg|jpg|png|gif)$/u and action == :to_html
            # allow as default
            # TODO
            # refactor as normal option
            # currently, support fachinfo/patinfo format only
            require 'ydocx/templates/fachinfo'
            options.merge!({:style => :frame})
          else
            self.error "#{self.command}: exit with #{option}: Unknown option"
          end
        end
        if !args.include?('-f') and !args.include?('--format')
          # default fachinfo
          require 'ydocx/templates/fachinfo'
          options.merge!({:style => :frame}) if action == :to_html
        end
        options
      end
      def report(action, path)
        puts "#{self.command}: generated #{File.expand_path(path)}"
        exit
      end
      def run(action=:to_html)
        argv = ARGV.dup
        if argv.empty? or argv[0] =~ @@help
          self.help
        elsif argv[0] =~ @@version
          self.version
        else
          file = argv.shift
          path = File.expand_path(file)
          if !File.exist?(path)
            self.error "#{self.command}: cannot open #{file}: No such file"
          elsif !File.extname(path).match(/^\.docx$/)
            self.error "#{self.command}: cannot open #{file}: Not a docx file"
          else
            options = self.parse(action, argv)
            doc = YDocx::Document.open(path, options)
            doc.send(action, path, options)
            ext = self.extname(action)
            self.report action, doc.output_file(ext[1..-1])
          end
        end
      end
      def version
        puts "#{self.command}: version #{VERSION}"
        exit
      end
    end
  end
end
