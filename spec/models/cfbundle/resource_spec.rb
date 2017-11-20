require 'spec_helper'
require 'cfbundle'
require 'zip'

RSpec.shared_examples 'an iOS application with resources' do
  let(:bundle) { CFBundle::Bundle.open file }
  after(:each) { bundle.close }

  describe '.foreach' do
    it 'finds the localized resource with the development localization' do
      expect(bundle.find_resource('Test', extension: 'strings').path)
        .to eq('en.lproj/Test.strings')
    end
    it 'finds the localized resource with the preferred languages' do
      expect(bundle.find_resources(nil,
                                   extension: 'strings',
                                   preferred_languages: ['fr-FR']).map(&:path))
        .to eq(['fr.lproj/Test.strings'])
    end
    it 'finds the appropriate product variant' do
      expect(bundle.find_resource(
        'AppIcon76x76@2x', extension: 'png', product: 'ipad'
      ).path).to eq('AppIcon76x76@2x~ipad.png')
    end
    it 'falls back to the original resource when the variant is not found' do
      expect(bundle.find_resource(
        'AppIcon60x60@2x', extension: 'png', product: 'ipad'
      ).path).to eq('AppIcon60x60@2x.png')
    end
    it 'does not return a product variant unless requested' do
      expect(bundle.find_resource(
               'AppIcon76x76@2x', extension: 'png'
      )).to be_nil
    end
    it 'accepts a Regexp for the name' do
      expect(bundle.find_resources(
        /\AAppIcon60x60(@\dx)?\z/, extension: 'png'
      ).map(&:path)).to eq(['AppIcon60x60@2x.png', 'AppIcon60x60@3x.png'])
    end
  end

  describe '#open' do
    let(:resource) { bundle.find_resource('PkgInfo') }
    it 'opens the resource for reading' do
      expect(resource.open(&:read)).to eq('APPL????')
    end
  end
end

RSpec.describe CFBundle::Resource do
  context "with 'iOS App.app'" do
    let(:file) { file_fixture('iOS App.app') }
    it_behaves_like 'an iOS application with resources'
  end

  context "with 'iOS App.ipa'" do
    let(:file) { file_fixture('iOS App.ipa') }
    it_behaves_like 'an iOS application with resources'
  end
end
