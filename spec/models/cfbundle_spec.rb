require 'spec_helper'
require 'cfbundle'

RSpec.describe CFBundle do
  it 'is version 0.1.0' do
    expect(subject::VERSION).to eq('0.1.0')
  end
end
