#!/usr/bin/env ruby
# encoding: utf-8

require 'ydocx'

module YDocx
  class Command
    class << self
      @@help    = /^\-(h|\-help)$/u
      @@format  = /^\-(f|\-format)$/u
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
  -v, --version   Show version.
        BANNER
        puts banner
        exit
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
            options = {}
            if option = argv.shift
              if option =~ @@format
                case argv[0]
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
            else
              # default fachinfo
              require 'ydocx/templates/fachinfo'
              options.merge!({:style => :frame}) if action == :to_html
            end
            doc = YDocx::Document.open(path)
            doc.send(action, path, options)
            self.report action, doc.output_file(self.extname(action))
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
