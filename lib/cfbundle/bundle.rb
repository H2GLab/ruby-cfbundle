require 'cfbundle/constants'
require 'cfbundle/localization'
require 'cfbundle/path_utils'
require 'cfbundle/plist'
require 'cfbundle/resource'
require 'cfbundle/storage_detection'

module CFBundle
  # A Bundle is an abstraction of a bundle accessible by the program.
  class Bundle
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
      @storage = StorageDetection.open(file)
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
      @info ||= Plist.load_info_plist(self)
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

    # Returns the name of the development language of the bundle.
    # @return [String, nil]
    # @see INFO_KEY_BUNDLE_DEVELOPMENT_REGION
    def development_localization
      info_string(CFBundle::INFO_KEY_BUNDLE_DEVELOPMENT_REGION)
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

    # Returns the path of the bundle's subdirectory that contains its resources.
    #
    # The path is relative to the bundle's path. For iOS application bundles,
    # as the resources directory is the bundle, this method returns a single dot
    # (+.+).
    # @return [String]
    # @see Resource
    def resources_directory
      case layout_version
      when 0 then 'Resources'
      when 2 then 'Contents/Resources'
      when 3 then '.'
      end
    end

    # Returns a list of all the localizations contained in the bundle.
    # @return [Array]
    def localizations
      @localizations ||= Localization.localizations_in(self)
    end

    # Returns an ordered list of preferred localizations contained in the
    # bundle.
    # @param preferred_languages [Array] An array of strings (or symbols)
    #        corresponding to a user's preferred languages.
    # @return [Array]
    def preferred_localizations(preferred_languages)
      Localization.preferred_localizations(localizations, preferred_languages)
    end

    # Returns the first {Resource} object that matches the specified parameters.
    #
    # @param name [String?, Rexgep?] The name to match or +nil+ to match any
    #        name.
    # @param extension [String?] The extension to match or +nil+ to match any
    #        extension.
    # @param subdirectory [String?] The name of the bundle subdirectory
    #        search.
    # @param localization [String?, Symbol?] A language identifier to restrict
    #        the search to a specific localization.
    # @param preferred_languages [Array] An array of strings (or symbols)
    #        corresponding to a user's preferred languages.
    # @param product [String?] The product to match or +nil+ to match any
    #        product.
    # @return [Resource?]
    # @see Resource.foreach
    def find_resource(name, extension: nil, subdirectory: nil,
                      localization: nil, preferred_languages: [], product: nil)
      Resource.foreach(
        self, name,
        extension: extension, subdirectory: subdirectory,
        localization: localization, preferred_languages: preferred_languages,
        product: product
      ).first
    end

    # Returns all the {Resource} objects that matches the specified parameters.
    #
    # @param name [String?, Rexgep?] The name to match or +nil+ to match any
    #        name.
    # @param extension [String?] The extension to match or +nil+ to match any
    #        extension.
    # @param subdirectory [String?] The name of the bundle subdirectory to
    #        search.
    # @param localization [String?, Symbol?] A language identifier to restrict
    #        the search to a specific localization.
    # @param preferred_languages [Array] An array of strings (or symbols)
    #        corresponding to a user's preferred languages.
    # @param product [String?] The product to match or +nil+ to match any
    #        product.
    # @return [Array] An array of {Resource} objects.
    # @see Resource.foreach
    def find_resources(name, extension: nil, subdirectory: nil,
                       localization: nil, preferred_languages: [], product: nil)
      Resource.foreach(
        self, name,
        extension: extension, subdirectory: subdirectory,
        localization: localization, preferred_languages: preferred_languages,
        product: product
      ).to_a
    end

    private

    def layout_version
      @layout_version ||= detect_layout_version
    end

    def detect_layout_version
      return 2 if storage.directory? 'Contents'
      return 0 if storage.directory? 'Resources'
      3
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
