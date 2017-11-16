module CFBundle
  # @private
  #
  # Utility methods for manipulating paths
  module PathUtils
    class << self
      # Returns a new path formed by joining the strings using
      # +File::SEPARATOR+.
      #
      # The methods also makes sure to remove any trailing separator along with
      # path components that are empty, nil or a single dot (+.+) in order to
      # generate a canonical path.
      #
      # @param args [Array] An array of strings.
      # @return [String]
      def join(*args)
        args.compact!
        args.map! { |arg| arg.split(File::SEPARATOR) }
        args.flatten!
        args.reject! { |arg| arg == '.' }
        return '.' if args.empty?
        absolute = args.first == ''
        args.reject! { |arg| arg == '' }
        args.unshift('/') if absolute
        File.join(args)
      end

      # Splits the resource path into four components.
      #
      # The components are the resource's directory, name, product and
      # extension. The product is either empty or starts with a tilde. The
      # extension is either empty or starts with a dot.
      # @param path [String] The path to the resource.
      # @return [Array]
      # @see join_resource
      def split_resource(path)
        directory = File.dirname(path)
        extension = File.extname(path)
        basename = File.basename(path, extension)
        name, product = split_resource_name_and_product(basename)
        [directory, name, product, extension]
      end

      # Returns a new path formed by joining the resource components.
      # @param directory [String] The resource's directory.
      # @param name [String] The resource's name.
      # @param product [String] The resource's product. It should be empty or
      #                         start with a tilde.
      # @param extension [String] The resource's extension. It should be empty
      #                           or start with a dot.
      # @return [String]
      # @see split_resource
      def join_resource(directory, name, product, extension)
        filename = [name, product, extension].join
        join(directory, filename)
      end

      private

      def split_resource_name_and_product(basename)
        name, _, product = basename.rpartition('~')
        if name.empty? || product.empty?
          [basename, '']
        else
          [name, '~' + product]
        end
      end
    end
  end
end
