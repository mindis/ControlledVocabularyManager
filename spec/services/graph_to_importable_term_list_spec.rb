require 'rails_helper'

RSpec.describe GraphToImportableTermList do
  let(:graph) { instance_double("RDF::Graph") }
  let(:repository) { instance_double("StandardRepository") }
  let(:graph_to_terms) { instance_double("GraphToTerms") }
  let(:terms) { double("terms") }
  let(:termlist) { instance_double("ImportableTermList") }
  subject { GraphToImportableTermList.new(graph) }

  describe "#run" do
    before do
      expect(StandardRepository).to receive(:new).and_return(repository)
      expect(GraphToTerms).to receive(:new).and_return(graph_to_terms)
      expect(graph_to_terms).to receive(:run).and_return(terms)
      expect(ImportableTermList).to receive(:new).with(terms).and_return(termlist)
    end

    it "should return the ImportableTermList generated by GraphToTerms" do
      expect(subject.run).to eq(termlist)
    end
  end
end