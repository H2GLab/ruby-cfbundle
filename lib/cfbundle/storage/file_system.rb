require 'cfbundle/path_utils'
require 'cfbundle/storage/base'

module CFBundle
  module Storage
    # A bundle storage that reads from the file system.
    class FileSystem < Base
      # @param path [String] The path of the bundle on the file system.
      def initialize(path)
        @root = path
      end

      # (see Base#exist?)
      def exist?(path)
        find(path) != nil
      end

      # (see Base#file?)
      def file?(path)
        entry = find(path)
        !entry.nil? && File.file?(entry)
      end

      # (see Base#directory?)
      def directory?(path)
        entry = find(path)
        !entry.nil? && File.directory?(entry)
      end

      # (see Base#open)
      def open(path, &block)
        File.open find!(path), &block
      end

      private

      def find(path)
        entry = PathUtils.join(@root, path)
        entry if File.exist? entry
      end

      def find!(path)
        find(path) || raise(Errno::ENOENT, path)
      end
    end
  end
end
