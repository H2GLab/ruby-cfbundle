require 'cfpropertylist'

module CFBundle
  # @private
  #
  # Utility methods for manipulating Property list files.
  module Plist
    class << self
      # Loads the +Info.plist+ file in a bundle.
      # @param bundle [Bundle] The bundle to search.
      # @return [Hash]
      def load_info_plist(bundle)
        load_plist(bundle, info_plist_path_in(bundle))
      end

      # Loads a Propery list file in a bundle.
      # @param bundle [Bundle] The bundle to search.
      # @param path [String] The path to the Property list file in the bundle.
      # @return [Hash]
      def load_plist(bundle, path)
        data = bundle.storage.open(path, &:read)
        plist = CFPropertyList::List.new(data: data)
        CFPropertyList.native_types(plist.value)
      end

      private

      def info_plist_path_in(bundle)
        case bundle.send :layout_version
        when 0 then 'Resources/Info.plist'
        when 2 then 'Contents/Info.plist'
        when 3 then 'Info.plist'
        end
      end
    end
  end
end
