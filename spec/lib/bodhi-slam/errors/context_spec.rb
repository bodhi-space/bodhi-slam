require 'spec_helper'

describe Bodhi::ContextErrors do
  it "Extends Bodhi::Errors" do
    expect( Bodhi::ContextErrors.ancestors ).to include(Bodhi::Errors)
  end
end