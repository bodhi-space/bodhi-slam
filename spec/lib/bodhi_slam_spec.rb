require 'spec_helper'

describe BodhiSlam do
  describe ".context" do
    context "with valid params" do
      it "should yield a Bodhi::Context" do
        expect { |block| BodhiSlam.context({ server: "http://google.com", namespace: "test" }, &block) }.to yield_with_args(Bodhi::Context)
      end
    end
    
    context "with invalid params" do
      it "should raise Bodhi::ContextErrors" do
        expect{ BodhiSlam.context({ server: "test", namespace: "test" }){|context|} }.to raise_error(Bodhi::ContextErrors)
        
        begin
          BodhiSlam.context({ server: "test", namespace: nil }){|context|}
        rescue Bodhi::ContextErrors => e
          expect(e.full_messages).to match_array(["server must be a valid URL", "namespace is required"])
        end
      end
    end
  end

  describe ".define_resources(context, options={})" do
    let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

    it "raises Bodhi::ContextErrors if the context is invalid" do
      bad_context = Bodhi::Context.new
      expect{ BodhiSlam.define_resources(bad_context) }.to raise_error(Bodhi::ContextErrors)
    end

    it "returns only the types specified with the :include options" do
      resources = BodhiSlam.define_resources(context, include: ["Store", :SalesTransaction])
      expect(resources.size).to eq 2
      expect(Object.const_defined?("Store")).to be true
      expect(Object.const_defined?("SalesTransaction")).to be true

      #clean up
      ["Store", "SalesTransaction"].each{ |resource| Object.send(:remove_const, resource) }
    end

    it "returns all types except the ones specified with the :exclude options" do
      resources = BodhiSlam.define_resources(context, except: ["Store", :SalesTransaction])
      expect(resources.map(&:name)).to_not include ["Store", "SalesTransaction"]

      # clean up
      resources.map(&:name).each{ |resource| Object.send(:remove_const, resource) }
    end

    it "returns all types if no options are given" do
      resources = BodhiSlam.define_resources(context)
      expect(resources).to_not be_empty

      # clean up
      resources.map(&:name).each{ |resource| Object.send(:remove_const, resource) }
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

        #result.delete_if{ |type| ["BodhiEmailTemplate"].include?(type.name) }

        result.each do |type|
          puts "\033[32m--------------------------------------------------------\033[0m"
          puts "\033[33mBuilding\033[0m: \033[36m#{type}\033[0m"
          test = type.factory.build
          puts "\033[33mAttributes\033[0m: #{test.to_json}"
          unless test.valid?
            puts "\033[31mErrors Detected\033[0m: #{test.errors.messages}"
          end
        end
      end
    end
    
    context "with invalid context" do
      let(:context){ Bodhi::Context.new({ server: nil, namespace: nil }) }
      
      it "should raise Bodhi::ContextErrors" do
        expect{ BodhiSlam.analyze(context) }.to raise_error(Bodhi::ContextErrors)
      end
    end
  end
end