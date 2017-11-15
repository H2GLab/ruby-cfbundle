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
    end
  end
end
