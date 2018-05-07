require 'rails_helper'

RSpec.describe ControlledVocabManager::IdMinter do
  let(:minter) {described_class}

  describe "#generate_id" do
    it "should generate an 8 digit alpha numeric hash" do
      expect(minter.generate_id.length).to eq 8
    end
    it "should only include letters and numbers" do
      expect(minter.generate_id).not_to include(' ', '_', '$', '&')
    end
  end

end