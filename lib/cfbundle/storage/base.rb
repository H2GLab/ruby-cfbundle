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
      # @return false
      def exist?(path)
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

      # Invoked when the storage is no longer needed.
      #
      # The default implementation does nothing.
      # @return [void]
      def close; end
    end
  end
end