require 'spec_helper'

describe BodhiSlam do
  describe ".context" do
    context "with valid params" do
      it "should yield a Bodhi::Context" do
        expect { |block| BodhiSlam.context({ server: "http://google.com", namespace: "test" }, &block) }.to yield_with_args(Bodhi::Context)
      end
    end
    
    context "with invalid params" do
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.context({ server: "test", namespace: "test" }){|context|} }.to raise_error(Bodhi::Errors)
        
        begin
          BodhiSlam.context({ server: "test", namespace: nil }){|context|}
        rescue Exception => e
          expect(e.messages[:server]).to match_array(["must be a valid URL"])
          expect(e.messages[:namespace]).to match_array(["is required"])
        end
      end
    end
  end
  
  describe ".analyze" do
    context "with valid context" do
      let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }
      
      before do
        @type_names = Bodhi::Type.find_all(context).collect{ |type| type.name }
      end
      
      it "should return an array of the new type classes" do
        result = BodhiSlam.analyze(context)
        result_type_names = result.collect{ |type| type.name }
        
        expect(result).to be_a Array
        expect(result).to_not be_empty
        expect(result_type_names).to match_array(@type_names)

        result.each do |type|
          puts "Building: #{type}"
          test = FactoryGirl.build(type.name)
          puts test.to_json
          unless test.valid?
            puts "Errors: #{test.errors.messages}"
          else
            puts "Generated valid #{type}"
          end
        end
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise a Bodhi::Errors" do
        expect{ BodhiSlam.analyze(context) }.to raise_error(Bodhi::Errors)
      end
    end
  end
end