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

      # Opens a file in the storage.
      #
      # @param path [String] The path of the file to open.
      # @param block [Proc] An optional code block to execute with the opended
      #                     file.
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
