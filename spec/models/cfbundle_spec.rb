require 'spec_helper'
require 'cfbundle'

RSpec.describe CFBundle do
  it 'is version 0.2.2' do
    expect(subject::VERSION).to eq('0.2.2')
  end
end
