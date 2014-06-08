require "rugged"
require "rack/utils"
require "rack/mime"

module Rack
  module Git
    class File
      DIRECTORY_CONVERTER = -> (entries, env) {
        list = entries.map { |e| %Q!<li><a href="#{e}">#{e}</a></li>! }
        "<ul><li><a href=\"../\">../</a></li>#{list.join}</ul>"
      }

      def initialize(git_path, mime = Rack::Mime, dirctory_converter = DIRECTORY_CONVERTER)
        @repository = Rugged::Repository.new git_path
        @mime = mime
        @directory_converter = dirctory_converter
      end

      def call(env)
        unescaped_path = Rack::Utils.unescape(env["PATH_INFO"])
        walker =
          @repository.
          head.
          target.
          tree.
          walk(:postorder)
        oid = walker.find(->{ ["", {}] }) { |root, entry|
          case entry[:type]
          when :blob
            unescaped_path == "/#{root}#{entry[:name]}"
          when :tree
            # directory expects trailing slash
            unescaped_path == "/#{root}#{entry[:name]}/"
          else
            # never become here
            raise "Something wrong: #{e}"
          end
        }[1][:oid]

        return [404, {}, []] if oid.nil?

        case rugged_object = @repository.lookup(oid)
        when Rugged::Blob
          mime_type = @mime.mime_type(::File.extname(unescaped_path))
          [200, { "Content-Type" => mime_type }, [rugged_object.content]]
        when Rugged::Tree
          entries = []
          rugged_object.each { |e|
            case e[:type]
            when :blob
              entries << e[:name]
            when :tree
              # directory expects trailing slash
              entries << "#{e[:name]}/"
            else
              # never become here
              raise "Something wrong: #{e}"
            end
          }
          [200, {"Content-Type" => "text/html" }, [@directory_converter.call(entries, env)]]
        end
      end
    end
  end
end
