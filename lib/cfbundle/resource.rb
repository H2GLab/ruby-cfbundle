require 'cfbundle/path_utils'

module CFBundle
  # A {Resource} is an abstraction of file contained within a {Bundle}.
  class Resource
    # Returns the resource's enclosing bundle.
    # @return [Bundle]
    attr_reader :bundle

    # Returns the path to the resource within the bundle.
    # @return [String]
    attr_reader :path

    # @param bundle [Bundle] The resource's enclosing bundle.
    # @param path [String] The path of the resource within the bundle.
    def initialize(bundle, path)
      @bundle = bundle
      @path = path
      @directory, @name, @product, @extension = PathUtils.split_resource(path)
    end

    # Opens the resource for reading.
    #
    # With no associated block, the method returns an IO. If the optional block
    # is given, it will be passed the opened file and the file will
    # automatically be closed when the block terminates.
    # @yieldparam file [IO] The opened file. It is automatically closed when the
    #                       block terminates.
    # @return [Object] The return value to the block when a block is given.
    # @return [IO] The opened file. When no block is given.
    def open(&block)
      bundle.storage.open(path, &block)
    end

    # Enumerates the resources in a bundle that match the specified parameters.
    #
    # @param bundle [Bundle] The bundle that contains the resources.
    # @param name [String?] The name to match or +nil+ to match any name.
    # @param extension [String?] The extension to match or +nil+ to match any
    #        extension.
    # @param localization [String?, Symbol?] A language identifier to restrict
    #        the search to a specific localization.
    # @param preferred_languages [Array] An array of strings (or symbols)
    #        corresponding to a user's preferred languages.
    # @param product [String?] The product to match or +nil+ to match any
    #        product.
    # @yieldparam resource [Resource]
    # @return [nil] When a block is given.
    # @return [Enumerator] When no block is given.
    def self.foreach(bundle, name, extension: nil, subdirectory: nil,
                     localization: nil, preferred_languages: [], product: nil,
                     &block)
      enumerator = ::Enumerator.new do |y|
        enumerator = Enumerator.new(bundle, subdirectory, localization,
                                    preferred_languages)
        predicate = Predicate.new(name, extension, product)
        loop do
          resource = enumerator.next
          y << resource if resource.send(:match?, predicate)
        end
      end
      enumerator.each(&block)
    end

    private

    def match?(predicate)
      return false unless name_match?(predicate) &&
                          extension_match?(predicate) &&
                          product_match?(predicate)
      predicate.uniq?(@name, @extension)
    end

    def name_match?(predicate)
      predicate.name.nil? || @name == predicate.name
    end

    def extension_match?(predicate)
      predicate.extension.nil? || @extension == predicate.extension
    end

    def product_match?(predicate)
      return true if @product == predicate.product
      return false unless @product.empty?
      !bundle.storage.exist?(path_with_product(predicate.product))
    end

    def path_with_product(product)
      PathUtils.join_resource(@directory, @name, product, @extension)
    end

    # @private
    #
    # Performs the enumeration of a bundle's resources.
    class Enumerator
      # @param bundle [Bundle] The bundle that contains the resources.
      # @param subdirectory [String?] The name of the bundle subdirectory to
      #        search.
      # @param localization [String?, Symbol?] A language identifier to restrict
      #        the search to a specific localization.
      # @param preferred_languages [Array] An array of strings (or symbols)
      #        corresponding to a user's preferred languages.
      def initialize(bundle, subdirectory, localization, preferred_languages)
        @bundle = bundle
        @directory = PathUtils.join(bundle.resources_directory, subdirectory)
        @localizations = localizations_for(bundle, localization,
                                           preferred_languages)
        @enumerator = [].to_enum
      end

      # Returns the next resource in the bundle.
      #
      # @return [Resource]
      # @raise [StopIteration]
      def next
        Resource.new(@bundle, @enumerator.next)
      rescue StopIteration
        @enumerator = next_enumerator
        retry
      end

      private

      def next_enumerator
        loop do
          break if @localizations.empty?
          localization = @localizations.shift
          directory = localized_directory_for(localization)
          next unless @bundle.storage.directory?(directory)
          return @bundle.storage.foreach(directory)
        end
        raise StopIteration
      end

      def localized_directory_for(localization)
        return @directory unless localization
        PathUtils.join(@directory, localization + '.lproj')
      end

      def localizations_for(bundle, localization, preferred_languages)
        return [nil, localization.to_s] if localization
        [
          nil,
          *bundle.preferred_localizations(preferred_languages || []),
          bundle.development_localization
        ].uniq
      end
    end

    # @private
    #
    # Stores the parameters to select the matching resources while enumerating
    # the resources of a bundle.
    class Predicate
      # Returns the name to match or +nil+ to match any name.
      # @return [String?]
      attr_reader :name

      # Returns the extension to match or +nil+ to match any extension.
      # @return [String?]
      attr_reader :extension

      # Returns the product to match.
      # @return [String]
      attr_reader :product

      # @param name [String?] The name to match or +nil+ to match any name.
      # @param extension [String?] The extension to match or +nil+ to match any
      #                            extension.
      # @param product [String?] The product to match.
      def initialize(name, extension, product)
        @name = name
        @extension = extension_for(extension)
        @product = product_for(product)
        @keys = Set.new
      end

      # Ensures the given name and extension are unique during the enumeration.
      #
      # @param name [String] The resource name.
      # @param extension [String] The resource extension.
      def uniq?(name, extension)
        key = [name, extension].join
        return false if @keys.include?(key)
        @keys << key
        true
      end

      private

      def extension_for(extension)
        return extension if extension.nil? || extension.empty?
        extension.start_with?('.') ? extension : '.' + extension
      end

      def product_for(product)
        return '' if product.nil? || product.empty?
        product.start_with?('~') ? product : '~' + product
      end
    end
  end
end
