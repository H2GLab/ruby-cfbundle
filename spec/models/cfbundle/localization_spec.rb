require 'spec_helper'
require 'cfbundle/localization'

RSpec.describe CFBundle::Localization do
  describe '::preferred_localizations' do
    let(:result) do
      described_class.preferred_localizations localizations, preferred_languages
    end
    let(:localizations) { ['en', 'fr', 'fr-CA', 'gsw-CH'] }
    context 'when no language matches' do
      let(:preferred_languages) { ['de'] }
      it 'returns an empty array' do
        expect(result).to be_empty
      end
    end
    context 'when a language matches' do
      let(:preferred_languages) { ['de', 'fr', 'gsw-CH'] }
      it 'returns the language' do
        expect(result).to eq(['fr'])
      end
    end
    context 'when a regional language matches' do
      let(:preferred_languages) { ['de', 'fr-CA', 'en'] }
      it 'returns the regional language and the base language' do
        expect(result).to eq(['fr-CA', 'fr'])
      end
    end
    context 'when a base language matches' do
      let(:preferred_languages) { ['de', 'fr-FR', 'en'] }
      it 'returns the base language' do
        expect(result).to eq(['fr'])
      end
    end
    context 'when a different regional language matches' do
      let(:preferred_languages) { ['de', 'gsw-FR', 'en'] }
      it 'returns the regional language' do
        expect(result).to eq(['gsw-CH'])
      end
    end
  end
end
