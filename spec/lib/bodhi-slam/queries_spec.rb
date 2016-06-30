require 'spec_helper'

describe Bodhi::Query do
  before(:all) do
    @context = Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] })
    @type = Bodhi::Type.new(name: "TestResource", properties: { foo: { type: "String" }, bar: { type: "TestEmbeddedResource" }, baz: { type: "Integer" } })
    @embedded_type = Bodhi::Type.new(name: "TestEmbeddedResource", properties: { test: { type: "String" } }, embedded: true)

    @type.bodhi_context = @context
    @embedded_type.bodhi_context = @context

    @type.save!
    @embedded_type.save!

    Bodhi::Type.create_class_with(@type)
    Bodhi::Type.create_class_with(@embedded_type)
  end

  after(:all) do
    @type.delete!
    @embedded_type.delete!

    Object.send(:remove_const, :TestResource)
    Object.send(:remove_const, :TestEmbeddedResource)
  end

  before do
    @query = Bodhi::Query.new(TestResource)
  end

  after do
    TestResource.delete!(@context)
  end

  describe "Object Attributes" do
    describe "#klass" do
      it "is the Class of the resource to be queried" do
        expect(@query.klass).to eq TestResource
      end
    end

    describe "#criteria" do
      it "is an Hash containing all query conditions" do
        expect(@query.criteria).to be_a Hash
      end
    end

    describe "#fields" do
      it "is an Array of attributes to filter the query result by" do
        expect(@query.fields).to be_a Array
      end
    end

    describe "#paging" do
      it "is a Hash containing :limit and :page values" do
        expect(@query.paging).to be_a Hash
      end
    end

    describe "#sorting" do
      it "is a Hash containing :fields and :order values" do
        expect(@query.sorting).to be_a Hash
      end
    end

    describe "#context" do
      it "is a Bodhi::Context object" do
        @query.from(@context)
        expect(@query.context).to eq @context
      end
    end
  end

  describe "Instance Methods" do
    describe "#url" do
      it "formats a basic url string for the query" do
        @query.from(@context)
        expect(@query.url).to eq "/#{ENV['QA_TEST_NAMESPACE']}/resources/TestResource?"
        puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
      end

      context "with criteria" do
        it "adds single mongodb where query" do
          @query.where(test: { "$exists" => true })
          expect(@query.url).to eq "/resources/TestResource?where={\"test\":{\"$exists\":true}}"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end

        it "joins multiple criteria into an $and mongodb query" do
          @query.where(foo: "12345").and(bar: { "$in" => [1,2,3] })
          expect(@query.url).to eq "/resources/TestResource?where={\"foo\":\"12345\",\"bar\":{\"$in\":[1,2,3]}}"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end
      end

      context "with fields" do
        it "joins all fields into the query" do
          @query.select("name,foo,bar")
          expect(@query.url).to eq "/resources/TestResource?fields=name,foo,bar"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end

        it "ignores empty fields (,,,,)" do
          @query.select("name,foo,bar,,,,,")
          expect(@query.url).to eq "/resources/TestResource?fields=name,foo,bar"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end
      end

      context "with sorting" do
        it "adds the field to the query" do
          @query.sort("foo")
          expect(@query.url).to eq "/resources/TestResource?sort=foo"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end

        it "adds the sort order to the query" do
          @query.sort("foo", :desc)
          expect(@query.url).to eq "/resources/TestResource?sort=foo:desc"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end
      end

      context "with paging" do
        it "adds the page number to the query" do
          @query.page(2)
          expect(@query.url).to eq "/resources/TestResource?paging=page:2"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end

        it "adds the limit to the query" do
          @query.limit(10)
          expect(@query.url).to eq "/resources/TestResource?paging=limit:10"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end

        it "displays both paging and limit" do
          @query.page(2).limit(10)
          expect(@query.url).to eq "/resources/TestResource?paging=page:2,limit:10"
          puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
        end
      end
    end
    
    describe "#clear!" do
      it "resets all attributes in the Bodhi::Query object" do
        @query.from(@context).where(foo: "test").select("foo").limit(10).page(2).sort("foo", :desc)

        expect(@query.context).to_not be_nil
        expect(@query.criteria).to_not be_empty
        expect(@query.fields).to_not be_empty
        expect(@query.paging).to_not be_empty
        expect(@query.sorting).to_not be_empty

        @query.clear!

        expect(@query.context).to be_nil
        expect(@query.criteria).to be_empty
        expect(@query.fields).to be_empty
        expect(@query.paging).to be_empty
        expect(@query.sorting).to be_empty
      end
    end

    describe "#from(context)" do
      it "accepts a Bodhi::Context object as a parameter" do
        expect { @query.from("test") }.to raise_error(ArgumentError, "Expected Bodhi::Context but received String")
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.from(@context) ).to eq @query
      end

      it "sets the read only :context attribute on the Bodhi::Query object" do
        @query.from(@context)
        expect(@query.context).to eq @context
      end
    end

    describe "#where(query_string)" do
      it "accepts a JSON String as a parameter" do
        @query.where('{"test": "foo"}')
        expect(@query.criteria).to eq test: "foo"
      end

      it "accepts a Hash as a parameter" do
        @query.where(test: "foo")
        expect(@query.criteria).to eq test: "foo"
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.where(test: "foo") ).to eq @query
      end

      it "does not duplicate criteria" do
        @query.where(test: "foo").where(test: "foo")
        expect(@query.criteria).to eq test: "foo"
      end
    end

    describe "#select(comma_separated_string)" do
      it "accepts a String as a parameter" do
        expect { @query.select(123) }.to raise_error(ArgumentError, "Expected String but received Fixnum")
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.select("name") ).to eq @query
      end

      it "adds each attribute to the read only :fields array on the Bodhi::Query object" do
        @query.select("test,foo,bar")
        expect(@query.fields).to match_array ["test", "foo", "bar"]
      end

      it "does not add duplicate field names" do
        @query.select("test,test,test")
        expect(@query.fields).to contain_exactly("test")
      end
    end

    describe "#limit(number)" do
      it "accepts an Integer as a parameter" do
        expect { @query.limit("test") }.to raise_error(ArgumentError, "Expected Integer but received String")
      end

      it "must be less than or equal to 100" do
        expect { @query.limit(1000) }.to raise_error(ArgumentError, "Expected limit to be less than or equal to 100 but received 1000")
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.limit(2) ).to eq @query
      end

      it "sets the :paging attribute with the :limit key and the given value" do
        @query.limit(10)
        expect(@query.paging).to have_key :limit
        expect(@query.paging[:limit]).to eq 10
      end
    end

    describe "#page(number)" do
      it "accepts an Integer as a parameter" do
        expect { @query.page("test") }.to raise_error(ArgumentError, "Expected Integer but received String")
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.page(2) ).to eq @query
      end

      it "sets the :paging attribute with the :page key and the given value" do
        @query.page(10)
        expect(@query.paging).to have_key :page
        expect(@query.paging[:page]).to eq 10
      end
    end

    describe "#sort(field, order)" do
      it "accepts a String as a parameter" do
        expect { @query.sort(123) }.to raise_error(ArgumentError, "Expected String but received Fixnum")
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.sort("test",:desc) ).to eq @query
      end

      it "sets the :sorting attribute with the given params" do
        @query.sort("test", :desc)
        expect(@query.sorting[:field]).to eq "test"
        expect(@query.sorting[:order]).to eq :desc
      end
    end

    describe "#count" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.count }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).count }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and counts all matching records" do
        TestResource.factory.create_list(5, bodhi_context: @context, foo: "test")
        TestResource.factory.create_list(2, bodhi_context: @context, foo: "not_test")

        result = @query.from(@context).where(foo: "test").count
        puts "\033[33mFound\033[0m: \033[36m#{result}\033[0m"
        expect(result).to eq 5
      end
    end

    describe "#delete" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.delete }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).delete }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and counts all matching records" do
        TestResource.factory.create_list(5, bodhi_context: @context, foo: "test")
        TestResource.factory.create_list(2, bodhi_context: @context, foo: "not_test")

        result = @query.from(@context).where(foo: "test").delete
        expect(result["deleted"]).to eq 5

        result = @query.from(@context).where(foo: "test").all.size
        expect(result).to eq 0

        result = @query.from(@context).where(foo: "not_test").all.size
        expect(result).to eq 2
      end
    end

    describe "#all" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.all }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).all }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and returns an array of all records that match" do
        TestResource.factory.create_list(5, bodhi_context: @context, foo: "test")
        TestResource.factory.create_list(2, bodhi_context: @context, foo: "not_test")

        result = @query.from(@context).where(foo: "test").all
        puts "\033[33mFound Resources\033[0m: \033[36m#{result.map(&:attributes)}\033[0m"
        expect(result.size).to eq 5
      end
    end

    describe "#first" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.first }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).first }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and returns the first record that matches" do
        first_result = TestResource.factory.create_list(5, bodhi_context: @context, foo: "test").first

        result = @query.from(@context).where(foo: "test").first
        puts "\033[33mFound Resources\033[0m: \033[36m#{result.attributes}\033[0m"
        expect(result.foo).to eq first_result.foo
      end
    end

    describe "#last" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.last }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).last }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and returns the last record that matches" do
        last_result = TestResource.factory.create_list(5, bodhi_context: @context, foo: "test").last

        result = @query.from(@context).where(foo: "test").last
        puts "\033[33mFound Resources\033[0m: \033[36m#{result.attributes}\033[0m"
        expect(result.foo).to eq last_result.foo
      end
    end
  end
end