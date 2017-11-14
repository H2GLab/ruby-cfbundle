require 'spec_helper'
require 'cfbundle'
require 'zip'

shared_examples_for 'a bundle' do
  let(:subject) { described_class.open file }
  after(:each) { subject.close }
  context 'when opened with a block' do
    it 'yields' do
      expect { |block| described_class.open file, &block }
        .to yield_with_args(described_class)
    end
  end
end

shared_examples_for 'a framework' do
  it_behaves_like 'a bundle' do
    it 'loads the Info.plist' do
      expect(subject.build_version).to eq('14')
      expect(subject.display_name).to be_nil
      expect(subject.executable_path).to eq('Framework')
      expect(subject.identifier).to eq('test.developer.Framework')
      expect(subject.name).to eq('Framework')
      expect(subject.package_type).to eq(CFBundle::PACKAGE_TYPE_FRAMEWORK)
      expect(subject.release_version).to eq('1.0')
    end
  end
end

shared_examples_for 'an iOS application' do
  it_behaves_like 'a bundle' do
    it 'loads the Info.plist' do
      expect(subject.build_version).to eq('14')
      expect(subject.display_name).to be_nil
      expect(subject.executable_path).to eq('iOS App')
      expect(subject.identifier).to eq('test.developer.iOS-App')
      expect(subject.name).to eq('iOS App')
      expect(subject.package_type).to eq(CFBundle::PACKAGE_TYPE_APPLICATION)
      expect(subject.release_version).to eq('1.0')
    end
  end
end

shared_examples_for 'a macOS application' do
  it_behaves_like 'a bundle' do
    it 'loads the Info.plist' do
      expect(subject.build_version).to eq('14')
      expect(subject.display_name).to be_nil
      expect(subject.executable_path).to eq('Contents/MacOS/macOS App')
      expect(subject.identifier).to eq('test.developer.macOS-App')
      expect(subject.name).to eq('macOS App')
      expect(subject.package_type).to eq(CFBundle::PACKAGE_TYPE_APPLICATION)
      expect(subject.release_version).to eq('1.0')
    end
  end
end

shared_examples_for 'a bundle for an IO' do
  after(:each) { file.close }
  it 'keeps the IO open' do
    subject = described_class.open file
    subject.close
    expect { file.seek(0, IO::SEEK_SET) }.not_to raise_error
  end
end

RSpec.describe CFBundle::Bundle do
  context "with 'Framework.zip'" do
    let(:file) { file_fixture('Framework.zip') }
    it_behaves_like 'a framework'
    context 'without Rubyzip' do
      around(:each) do |example|
        begin
          zip = Object.send(:remove_const, 'Zip')
          example.run
        ensure
          Object.const_set('Zip', zip)
        end
      end
      it 'raises an exception' do
        expect { described_class.open file }
          .to raise_error "cannot open ZIP archive \"#{file}\" without Rubyzip"
      end
    end
  end

  context "with 'iOS App.app'" do
    let(:file) { file_fixture('iOS App.app') }
    it_behaves_like 'an iOS application'
  end

  context "with 'iOS App.ipa'" do
    let(:file) { file_fixture('iOS App.ipa') }
    it_behaves_like 'an iOS application'
  end

  context "with 'macOS App.zip'" do
    let(:file) { file_fixture('macOS App.zip') }
    it_behaves_like 'a macOS application'
  end

  context 'with nil' do
    let(:file) { nil }
    it 'raises an exception' do
      expect { described_class.open file }
        .to raise_error 'nil is not a bundle'
    end
  end

  context 'with empty folder' do
    let(:file) { '/var/empty' }
    it 'raises an exception' do
      expect { described_class.open file }
        .to raise_error "\"#{file}\" is not a bundle"
    end
  end

  context 'with empty ZIP' do
    let(:file) { file_fixture('Empty.zip') }
    it 'raises an exception' do
      expect { described_class.open file }
        .to raise_error "no bundle found in ZIP archive \"#{file}\""
    end
  end

  context 'with an ambiguous ZIP' do
    let(:file) { file_fixture('Ambiguous.zip') }
    it 'raises an exception' do
      expect { described_class.open file }
        .to raise_error "several bundles found in ZIP archive \"#{file}\""
    end
  end

  context "with an IO to 'iOS App.ipa'" do
    let(:file) { File.open file_fixture('iOS App.ipa') }
    it_behaves_like 'a bundle for an IO' do
      it_behaves_like 'an iOS application'
    end
  end

  context "with a StringIO to 'macOS App.zip'" do
    let(:file) { File.open file_fixture('macOS App.zip') }
    it_behaves_like 'a bundle for an IO' do
      it_behaves_like 'a macOS application'
    end
  end

  context "with an UploadedFile to 'iOS App.ipa'" do
    let(:file) do
      file = Tempfile.new
      file.binmode
      file.define_singleton_method(:original_filename) { 'iOS App.ipa' }
      file.write File.open(file_fixture('iOS App.ipa'), &:read)
      file
    end
    it_behaves_like 'a bundle for an IO' do
      it_behaves_like 'an iOS application'
    end
  end
end
