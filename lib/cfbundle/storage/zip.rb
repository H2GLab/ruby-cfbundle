require 'cfbundle/path_utils'
require 'cfbundle/storage/base'

module CFBundle
  module Storage
    # A bundle storage that reads from a ZIP archive.
    class Zip < Base
      # @param zip [Zip::File] The Zip file containing the bundle.
      # @param path [String] The path of the bundle within the Zip file.
      # @param skip_close [Boolean] Whether the storage should skip closing
      #                             the Zip file when receiving {#close}.
      def initialize(zip, path, skip_close: false)
        @zip = zip
        @root = path
        @skip_close = skip_close
      end

      # Returns whether a given path exists within the storage.
      #
      # @param path [String] The path of a file or directory, relative to the
      #                      storage.
      def exist?(path)
        entry(path) != nil
      end

      # (see Base#open)
      def open(path, &block)
        entry!(path).get_input_stream(&block)
      end

      # Invoked when the storage is no longer needed.
      #
      # This method closes the underlying Zip file unless the storage was
      # initialized with +skip_close: true+.
      # @return [void]
      def close
        @zip.close unless @skip_close
      end

      private

      def entry(path)
        name = PathUtils.join(@root, path)
        @zip.find_entry name
      end

      def entry!(path)
        entry(path) || raise(Errno::ENOENT, path)
      end
    end
  end
end
