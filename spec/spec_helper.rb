require 'pathname'
require 'simplecov'
SimpleCov.start

RSpec.shared_context 'default' do
  let(:files_dir) { File.expand_path('../fixtures/files/', __FILE__) }

  def file_fixture(path)
    Pathname.new(files_dir) + path
  end
end

RSpec.configure do |config|
  config.include_context 'default'
end
