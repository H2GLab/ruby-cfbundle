module CFBundle
  module Storage
    # The {Storage::Base} class defines the methods required to access a
    # bundle's underlying storage.
    #
    # Most of the time, you don't need to concern youself with storages as
    # {CFBundle::Bundle.open} and {CFBundle::Bundle#initialize}
    # automatically detect and instantiate the appropriate storage.
    class Base
      # Returns whether a given path exists within the storage.
      #
      # @param path [String] The path of a file or directory, relative to the
      #                      storage.
      def exist?(path)
        # :nocov:
        false
        # :nocov:
      end

      # Returns whether a given file exists within the storage.
      #
      # @param path [String] The path of a file, relative to the storage.
      def file?(path)
        # :nocov:
        false
        # :nocov:
      end

      # Returns whether a given directory exists within the storage.
      #
      # @param path [String] The path of a directory, relative to the storage.
      def directory?(path)
        # :nocov:
        false
        # :nocov:
      end

      # Opens a file for reading in the storage.
      #
      # @param path [String] The path of the file to open.
      # @yieldparam file [IO] The opened file. It is automatically closed when
      #                       the block terminates.
      # @return [Object] The return value of the block when a block if given.
      # @return [IO] The opened file when no block is given.
      def open(path, &block)
        # :nocov:
        raise(Errno::ENOENT, path)
        # :nocov:
      end

      # Returns an enumerator that enumerates the files contained in a
      # directory.
      #
      # @param path [String] The path to the directory to enumerate.
      # @return [Enumerator]
      def foreach(path)
        # :nocov:
        raise(Errno::ENOENT, path)
        # :nocov:
      end

      # Invoked when the storage is no longer needed.
      #
      # The default implementation does nothing.
      # @return [void]
      def close; end
    end
  end
end
