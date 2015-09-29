require 'spec_helper'

describe Bodhi::Query do
  let(:context){ Bodhi::Context.new({ server: ENV['QA_TEST_SERVER'], namespace: ENV['QA_TEST_NAMESPACE'], cookie: ENV['QA_TEST_COOKIE'] }) }

  before do
    Object.const_set("Store", Class.new{ include Bodhi::Resource; attr_accessor :name, :store_number, :display_name })
    Store.factory.add_generator(:name, type: "String", is_not_blank: true)
    Store.factory.add_generator(:store_number, type: "String", is_not_blank: true)
    Store.factory.add_generator(:display_name, type: "String")
    @query = Bodhi::Query.new(Store)
  end

  after do
    Object.send(:remove_const, :Store)
  end

  describe "Object Attributes" do
    describe "#klass" do
      it "is the Class of the resource to be queried" do
        expect(@query.klass).to eq Store
      end
    end

    describe "#criteria" do
      it "is an Array of all query conditions" do
        expect(@query.criteria).to be_a Array
      end
    end

    describe "#fields" do
      it "is a comma separated Array of attributes to filter the query result by" do
        expect(@query.fields).to be_a Array
      end
    end

    describe "#paging" do
      it "is a Hash" do
        expect(@query.paging).to be_a Hash
      end
    end

    describe "#sorting" do
      it "is a Hash" do
        expect(@query.sorting).to be_a Hash
      end
    end

    describe "#context" do
      it "is a Bodhi::Context object" do
        @query.from(context)
        expect(@query.context).to eq context
      end
    end

    describe "#url" do
      it "formats a basic url string for the query" do
        @query.from(context)
        expect(@query.url).to eq "/#{ENV['QA_TEST_NAMESPACE']}/resources/Store?"
      end

      context "with criteria" do
        it "adds single mongodb where query" do
          @query.where("{test: { $exists: true }}")
          expect(@query.url).to eq "/resources/Store?where={test:{$exists:true}}"
        end

        it "joins multiple criteria into an $and mongodb query" do
          @query.where("{test: { $exists: true }}").and("{foo: 'bar'}").and("{test: 10}")
          expect(@query.url).to eq "/resources/Store?where={$and:[{test:{$exists:true}},{foo:'bar'},{test:10}]}"
        end
      end

      context "with fields" do
        it "joins all fields into the query" do
          @query.select("name,foo,bar")
          expect(@query.url).to eq "/resources/Store?fields=name,foo,bar"
        end

        it "ignores empty fields (,,,,)" do
          @query.select("name,foo,bar,,,,,")
          expect(@query.url).to eq "/resources/Store?fields=name,foo,bar"
        end
      end

      context "with sorting" do
        it "adds the field to the query" do
          @query.sort("foo")
          expect(@query.url).to eq "/resources/Store?sort=foo"
        end

        it "adds the sort order to the query" do
          @query.sort("foo", :desc)
          expect(@query.url).to eq "/resources/Store?sort=foo:desc"
        end
      end

      context "with paging" do
        it "adds the page number to the query" do
          @query.page(2)
          expect(@query.url).to eq "/resources/Store?paging=page:2"
        end

        it "adds the limit to the query" do
          @query.limit(10)
          expect(@query.url).to eq "/resources/Store?paging=limit:10"
        end

        it "displays both paging and limit" do
          @query.page(2).limit(10)
          expect(@query.url).to eq "/resources/Store?paging=page:2,limit:10"
        end
      end

      it "returns the query in url format" do
        @query.from(context).where("{test: { $exists: true }}")
        expect(@query.url).to eq "/#{ENV['QA_TEST_NAMESPACE']}/resources/Store?where={test:{$exists:true}}"
        puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"

        @query.where("{test: 10}").and("{foo: 'bar'}")
        expect(@query.url).to eq "/#{ENV['QA_TEST_NAMESPACE']}/resources/Store?where={$and:[{test:{$exists:true}},{test:10},{foo:'bar'}]}"
        puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"

        @query.select("name,foo,bar")
        expect(@query.url).to eq "/#{ENV['QA_TEST_NAMESPACE']}/resources/Store?where={$and:[{test:{$exists:true}},{test:10},{foo:'bar'}]}&fields=name,foo,bar"
        puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"

        @query.limit(10).page(2).sort("foo", :desc)
        expect(@query.url).to eq "/#{ENV['QA_TEST_NAMESPACE']}/resources/Store?where={$and:[{test:{$exists:true}},{test:10},{foo:'bar'}]}&fields=name,foo,bar&paging=page:2,limit:10&sort=foo:desc"
        puts "\033[33mQuery URL\033[0m: \033[36m#{@query.url}\033[0m"
      end
    end
  end

  describe "Instance Methods" do
    describe "#clear!" do
      it "resets all attributes in the Bodhi::Query object" do
        @query.from(context).where("{test}").select("foo").limit(10).page(2).sort("foo", :desc)

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
        expect( @query.from(context) ).to eq @query
      end

      it "sets the read only :context attribute on the Bodhi::Query object" do
        @query.from(context)
        expect(@query.context).to eq context
      end
    end

    describe "#where(query_string)" do
      it "accepts a String as a parameter" do
        expect { @query.where(123) }.to raise_error(ArgumentError, "Expected String but received Fixnum")
      end

      it "returns the Bodhi::Query object for method chaining" do
        expect( @query.where("{test}") ).to eq @query
      end

      it "adds the query string to the read only :criteria array on the Bodhi::Query object" do
        @query.where("{test}")
        expect(@query.criteria).to include "{test}"
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

    describe "#all" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.all }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).all }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and returns an array of all records that match" do
        test_stores = Store.factory.create_list(5, context, display_name: "test")
        not_test_stores = Store.factory.create_list(2, context, display_name: "not_test")

        result = @query.from(context).where("{display_name: 'test'}").all
        puts "\033[33mFound Resources\033[0m: \033[36m#{result.map(&:attributes)}\033[0m"
        expect(result.size).to eq 5

        test_stores.each{|store| store.delete! }
        not_test_stores.each{|store| store.delete! }
      end
    end

    describe "#first" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.first }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).first }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and returns the first record that matches" do
        test_stores = Store.factory.create_list(5, context, display_name: "test")
        first_store = test_stores.first

        result = @query.from(context).where("{display_name: 'test'}").first
        puts "\033[33mFound Resources\033[0m: \033[36m#{result.attributes}\033[0m"
        expect(result.name).to eq first_store.name

        test_stores.each{|store| store.delete! }
      end
    end

    describe "#last" do
      it "validates the Bodhi::Context before invoking the query" do
        bad_context = Bodhi::Context.new({ server: "test", namespace: nil, cookie: nil })

        expect { @query.last }.to raise_error(ArgumentError, "a Bodhi::Context is required to query the API")
        expect { @query.from(bad_context).last }.to raise_error(Bodhi::ContextErrors, '["server must be a valid URL", "namespace is required"]')
      end

      it "invokes the query and returns the last record that matches" do
        test_stores = Store.factory.create_list(5, context, display_name: "test")
        last_store = test_stores.last

        result = @query.from(context).where("{display_name: 'test'}").last
        puts "\033[33mFound Resources\033[0m: \033[36m#{result.attributes}\033[0m"
        expect(result.name).to eq last_store.name

        test_stores.each{|store| store.delete! }
      end
    end
  end
end