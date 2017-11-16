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
        find(path) != nil
      end

      # (see Base#open)
      def open(path, &block)
        find!(path).get_input_stream(&block)
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

      def find(path, symlinks = Set.new)
        name = PathUtils.join(@root, path)
        entry = @zip.find_entry name
        if entry.nil?
          find_in_parent(path, symlinks)
        elsif entry.symlink?
          find_symlink(entry.get_input_stream(&:read), path, symlinks)
        else
          entry
        end
      end

      def find!(path)
        find(path) || raise(Errno::ENOENT, path)
      end

      def find_in_parent(path, symlinks)
        directory, filename = File.split(path)
        return if ['.', '/'].include? filename
        entry = find(directory, symlinks)
        return unless entry && entry.directory?
        @zip.find_entry File.join(entry.name, filename)
      end

      def find_symlink(path, symlink, symlinks)
        return if path.start_with?('/') || symlinks.include?(symlink)
        symlinks << symlink
        resolved_path = PathUtils.join(File.dirname(symlink), path)
        find(resolved_path, symlinks)
      end
    end
  end
end
