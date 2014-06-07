require "rugged"
require "rack/utils"
require "rack/mime"

module Rack
  module Git
    class File
      def initialize(git_path, mime = Rack::Mime)
        @repository = Rugged::Repository.new git_path
        @mime = mime
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
          root = root.empty? ? "/" : root
          unescaped_path == "#{root}#{entry[:name]}"
        }[1][:oid]
        if oid
          mime_type = @mime.mime_type(::File.extname(unescaped_path))
          [200, { "Content-Type" => mime_type }, [@repository.lookup(oid).content]]
        else
          [404, {}, []]
        end
      end
    end
  end
end
