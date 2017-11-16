module CFBundle
  # @private
  #
  # Utility methods to perform localization.
  module Localization
    # The file extension of localization directories.
    FILE_EXTENSION = '.lproj'.freeze

    class << self
      # Returns all the localizations contained in a bundle.
      # @param bundle [Bundle] The bundle to search.
      # @return [Array]
      def localizations_in(bundle)
        return [] unless bundle.storage.directory?(bundle.resources_directory)
        bundle.storage
              .foreach(bundle.resources_directory)
              .select { |path| File.extname(path) == FILE_EXTENSION }
              .map { |path| File.basename(path, FILE_EXTENSION) }
      end

      # Returns an ordered list of preferred localizations contained in a
      # bundle.
      # @param localizations [Array] An array of localization identifiers.
      # @param preferred_languages [Array] An array of strings (or symbols)
      #        corresponding to a user's preferred languages.
      # @return [Array]
      # @see Bundle#localizations
      def preferred_localizations(localizations, preferred_languages)
        preferred_languages.each do |language|
          result = matching_localizations(localizations, language)
          return result unless result.empty?
          result = alternate_regional_localizations(localizations, language)
          return result unless result.empty?
        end
        []
      end

      private

      def matching_localizations(localizations, language)
        result = []
        loop do
          if localizations.include?(language.to_s) ||
             localizations.include?(language.to_sym)
            result << language
          end
          language = language.to_s.rpartition('-').first
          break if language.empty?
        end
        result
      end

      def alternate_regional_localizations(localizations, language)
        loop do
          language = language.to_s.rpartition('-').first
          return [] if language.empty?
          prefix = language + '-'
          match = localizations.find do |localization|
            localization.start_with?(prefix)
          end
          return [match.to_s] if match
        end
      end
    end
  end
end
