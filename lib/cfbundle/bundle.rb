require 'cfbundle/constants'
require 'cfbundle/path_utils'
require 'cfbundle/storage_detection'
require 'cfpropertylist'

module CFBundle
  # A Bundle is an abstraction of a bundle accessible by the program.
  class Bundle
    include CFBundle::StorageDetection

    # Opens a bundle.
    #
    # With no associated block, {open} is a synonym for {initialize new}. If the
    # optional code block is given, it will be passed the opened bundle as an
    # argument and the Bundle object will automatically be closed when the block
    # terminates. The value of the block will be returned from the method.
    #
    # @param file [Object] The file to open. See {initialize} for a description
    #                      of the supported values.
    # @yieldparam bundle [Bundle] The opened bundle. It is automatically closed
    #                              when the block terminates.
    # @return [Object] The return value of the block when a block if given.
    # @return [Bundle] The opened bundle when no block is given.
    def self.open(file)
      bundle = new(file)
      return bundle unless block_given?
      begin
        yield bundle
      ensure
        bundle.close
      end
    end

    # Opens the bundle and returns a new Bundle object.
    #
    # A new {storage} is automatically created from the +file+ parameter:
    # * If the file is a path to a bundle directory, a new {Storage::FileSystem}
    #   is created that references the bundle at the path.
    # * If the file is an +IO+ or a path to a ZIP archive, a new {Storage::Zip}
    #   is created that references the bundle within the archive.
    #   The +rubyzip+ gem must be loaded and the archive is expected to contain
    #   a single bundle at its root (or inside a +Payload+ directory for +.ipa+
    #   archives).
    # * If the file is a {Storage::Base}, it is used as the bundle's storage.
    #
    # You should send +#close+ when the bundle is no longer needed.
    #
    # Note that storages created from an exisiting +IO+ do not automatically
    # close the file when the bundle is closed.
    #
    # @param file [Object] The file to open.
    # @raise [ArgumentError] If the file cannot be opened.
    def initialize(file)
      @storage = open_storage(file)
    end

    # Closes the bundle and its underlying storage.
    # @return [void]
    def close
      @storage.close
    end

    # The abstract storage used by the bundle.
    #
    # The storage implements the methods that are used by Bundle to read the
    # bundle from the underlying storage (ZIP archive or file system).
    #
    # @return [Storage::Base]
    # @see Storage::FileSystem
    # @see Storage::Zip
    attr_reader :storage

    # Returns the bundle's information property list hash.
    # @return [Hash]
    def info
      @info ||= load_plist(info_plist_path)
    end

    # Returns the bundle identifier from the bundle's information property list.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_IDENTIFIER
    def identifier
      info_string(CFBundle::INFO_KEY_BUNDLE_IDENTIFIER)
    end

    # Returns the bundle's build version number.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_VERSION
    def build_version
      info_string(CFBundle::INFO_KEY_BUNDLE_VERSION)
    end

    # Returns the bundle's release version number.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_SHORT_VERSION_STRING
    def release_version
      info_string(CFBundle::INFO_KEY_BUNDLE_SHORT_VERSION_STRING)
    end

    # Returns the bundle's OS Type code.
    #
    # The value for this key consists of a four-letter code.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_PACKAGE_TYPE
    # @see PACKAGE_TYPE_APPLICATION
    # @see PACKAGE_TYPE_BUNDLE
    # @see PACKAGE_TYPE_FRAMEWORK
    def package_type
      info_string(CFBundle::INFO_KEY_BUNDLE_PACKAGE_TYPE)
    end

    # Returns the short name of the bundle.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_NAME
    def name
      info_string(CFBundle::INFO_KEY_BUNDLE_NAME)
    end

    # Returns the user-visible name of the bundle.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_DISPLAY_NAME
    def display_name
      info_string(CFBundle::INFO_KEY_BUNDLE_DISPLAY_NAME)
    end

    # Returns the name of the bundle's executable file.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_EXECUTABLE
    def executable_name
      info_string(CFBundle::INFO_KEY_BUNDLE_EXECUTABLE)
    end

    # Returns the path of the bundle's executable file.
    #
    # The executable's path is relative to the bundle's path.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_EXECUTABLE
    def executable_path
      @executable_path ||=
        executable_name && lookup_executable_path(executable_name)
    end

    private

    def load_plist(path)
      data = storage.open(path, &:read)
      plist = CFPropertyList::List.new(data: data)
      CFPropertyList.native_types(plist.value)
    end

    def info_plist_path
      case layout_version
      when 0 then 'Resources/Info.plist'
      when 2 then 'Contents/Info.plist'
      when 3 then 'Info.plist'
      end
    end

    def layout_version
      @layout_version ||=
        if storage.directory? 'Contents'
          2
        elsif storage.directory? 'Resources'
          0
        else
          3
        end
    end

    def info_string(key)
      value = info[key.to_s]
      value.to_s unless value.nil?
    end

    def lookup_executable_path(name)
      root = layout_version == 2 ? 'Contents' : '.'
      path = PathUtils.join(root, 'MacOS', name)
      return path if storage.file? path
      path = PathUtils.join(root, name)
      return path if storage.file? path
    end
  end
end
