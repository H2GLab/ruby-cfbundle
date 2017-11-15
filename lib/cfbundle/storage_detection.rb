require 'cfbundle/storage/base'
require 'cfbundle/storage/file_system'
require 'cfbundle/storage/zip'

module CFBundle
  # @private
  # This module implements the methods required to automatically detect and
  # instantiate the storage in {Bundle.open} and {Bundle#initialize}.
  module StorageDetection
    private

    def open_storage(file)
      storage = open_as_storage(file) ||
                open_as_io(file) ||
                open_as_path(file)
      raise "#{file.inspect} is not a bundle" unless storage
      storage
    end

    def path_for(file)
      if file.is_a? String
        file
      elsif file.respond_to? :to_path
        file.to_path
      end
    end

    def open_as_storage(file)
      file if file.is_a?(Storage::Base)
    end

    def open_as_path(file)
      path = path_for(file) || return
      ext = File.extname(path)
      if File.directory?(path) && ext != ''
        Storage::FileSystem.new(file)
      elsif ['.ipa', '.zip'].include? ext
        open_zip_path(path)
      end
    end

    def open_as_io(file)
      open_zip_io(file.to_io) if file.respond_to?(:to_io)
    end

    def open_zip_path(path)
      open_zip_file(path, &:open)
    end

    def open_zip_io(io)
      open_zip_file(io, &:open_buffer)
    end

    def open_zip_file(file, skip_close: false)
      unless defined?(Zip)
        raise "cannot open ZIP archive #{file.inspect} without Rubyzip"
      end
      zip = yield(Zip::File, file)
      entry = matching_zip_entry(zip)
      Storage::Zip.new(zip, entry.name, skip_close: skip_close)
    end

    def matching_zip_entry(zip)
      entries = zip.entries.select { |entry| zip_entry_match?(entry) }
      case entries.count
      when 1
        entries.first
      when 0
        raise "no bundle found in ZIP archive \"#{zip}\""
      else
        raise "several bundles found in ZIP archive \"#{zip}\""
      end
    end

    def zip_entry_match?(entry)
      entry.directory? &&
        [nil, 'Payload/'].include?(entry.parent_as_string) &&
        File.extname(entry.name) != ''
    end
  end
end
