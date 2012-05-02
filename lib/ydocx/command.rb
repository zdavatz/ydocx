#!/usr/bin/env ruby
# encoding: utf-8

require 'ydocx/document'

module YDocx
  class Command
    class << self
      @@help = /^\-(h|\-help)$/u
      @@format = /^\-(f|\-format)$/u
      def error(message='')
        puts message
        puts "see `#{self.command} --help`"
        exit
      end
      def command
        File.basename $0
      end
      def help
        banner = <<-BANNER
Usage: #{$0} file [options]
  -f, --format    Format of style and chapter {fi|fachinfo}, default none.
  -h, --help      Display this help message.
        BANNER
        puts banner
        exit
      end
      def report(action, path)
        dir = File.dirname path
        base = File.basename path, '.docx'
        ext = (action == :to_xml) ? '.xml' : '.html'
        puts "#{self.command}: generated #{dir}/#{base}#{ext}"
        exit
      end
      def run(action=:to_html)
        argv = ARGV.dup
        if argv.empty? or argv[0] =~ @@help
          self.help
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
                  # TODO style option?
                  options.merge!({:style => :frame}) if action == :to_html
                when 'pi', 'patinfo'
                  # pending
                else
                  self.error "#{self.command}: exit with #{option}: Invalid argument"
                end
              elsif option =~ @@help
                self.help
              else
                self.error "#{self.command}: exit with #{option}: Unknown option"
              end
            end
            YDocx::Document.open(path).send(action, path, options)
            self.report action, path
          end
        end
      end
    end
  end
end
