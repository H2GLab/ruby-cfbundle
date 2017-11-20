require 'spec_helper'
require 'cfbundle'

RSpec.describe CFBundle do
  it 'is version 0.2.0' do
    expect(subject::VERSION).to eq('0.2.0')
  end
end
