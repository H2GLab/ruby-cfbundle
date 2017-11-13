require 'cfbundle/storage/base'

module CFBundle
  module Storage
    # A bundle storage that reads from the file system.
    class FileSystem < Base
      # @param path [String] The path of the bundle on the file system.
      def initialize(path)
        @root = path
      end

      # Returns whether a given path exists within the storage.
      #
      # @param path [String] The path of a file or directory, relative to the
      #                      storage.
      # @return false
      def exist?(path)
        entry(path) != nil
      end

      # (see Base#open)
      def open(path, &block)
        File.open entry!(path), &block
      end

      private

      def entry(path)
        entry = File.join @root, path
        entry if File.exist? entry
      end

      def entry!(path)
        entry(path) || raise(Errno::ENOENT, path)
      end
    end
  end
end
