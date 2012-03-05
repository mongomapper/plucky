require 'helper'

class OptionsHashTest < Test::Unit::TestCase
  include Plucky

  context "Plucky::OptionsHash" do
    should "delegate missing methods to the source hash" do
      hash = {:limit => 1, :skip => 1}
      options = OptionsHash.new(hash)
      options[:skip].should      == 1
      options[:limit].should     == 1
      options.keys.to_set.should == [:limit, :skip].to_set
    end

    context "#initialize_copy" do
      setup do
        @original = OptionsHash.new(:fields => {:name => true}, :sort => :name, :limit => 10)
        @cloned   = @original.clone
      end

      should "duplicate source hash" do
        @cloned.source.should_not equal(@original.source)
      end

      should "clone duplicable? values" do
        @cloned[:fields].should_not equal(@original[:fields])
        @cloned[:sort].should_not equal(@original[:sort])
      end
    end

    context "#fields?" do
      should "be true if fields have been selected" do
        OptionsHash.new(:fields => :name).fields?.should be(true)
      end

      should "be false if no fields have been selected" do
        OptionsHash.new.fields?.should be(false)
      end
    end

    context "#[]=" do
      should "convert order to sort" do
        options = OptionsHash.new(:order => :foo)
        options[:order].should be_nil
        options[:sort].should == [['foo', 1]]
      end

      should "convert select to fields" do
        options = OptionsHash.new(:select => 'foo')
        options[:select].should be_nil
        options[:fields].should == ['foo']
      end

      should "convert offset to skip" do
        options = OptionsHash.new(:offset => 1)
        options[:offset].should be_nil
        options[:skip].should == 1
      end

      context ":fields" do
        setup   { @options = OptionsHash.new }
        subject { @options }

        should "default to nil" do
          subject[:fields].should be_nil
        end

        should "be nil if empty string" do
          subject[:fields] = ''
          subject[:fields].should be_nil
        end

        should "be nil if empty array" do
          subject[:fields] = []
          subject[:fields].should be_nil
        end

        should "work with array" do
          subject[:fields] = %w[one two]
          subject[:fields].should == %w[one two]
        end

        # Ruby 1.9.1 was sending array [{:age => 20}],
        # instead of hash.
        should "work with array that has one hash" do
          subject[:fields] = [{:age => 20}]
          subject[:fields].should == {:age => 20}
        end

        should "flatten multi-dimensional array" do
          subject[:fields] = [[:one, :two]]
          subject[:fields].should == [:one, :two]
        end

        should "work with symbol" do
          subject[:fields] = :one
          subject[:fields].should == [:one]
        end

        should "work with array of symbols" do
          subject[:fields] = [:one, :two]
          subject[:fields].should == [:one, :two]
        end

        should "work with hash" do
          subject[:fields] = {:one => 1, :two => -1}
          subject[:fields].should == {:one => 1, :two => -1}
        end

        should "convert comma separated list to array" do
          subject[:fields] = 'one, two'
          subject[:fields].should == %w[one two]
        end

        should "convert select" do
          subject[:select] = 'one, two'
          subject[:select].should be_nil
          subject[:fields].should == %w[one two]
        end
      end

      context ":limit" do
        setup   { @options = OptionsHash.new }
        subject { @options }

        should "default to nil" do
          subject[:limit].should be_nil
        end

        should "use limit provided" do
          subject[:limit] = 1
          subject[:limit].should == 1
        end

        should "convert string to integer" do
          subject[:limit] = '1'
          subject[:limit].should == 1
        end
      end

      context ":skip" do
        setup   { @options = OptionsHash.new }
        subject { @options }

        should "default to nil" do
          subject[:skip].should be_nil
        end

        should "use limit provided" do
          subject[:skip] = 1
          subject[:skip].should == 1
        end

        should "convert string to integer" do
          subject[:skip] = '1'
          subject[:skip].should == 1
        end

        should "be set from offset" do
          subject[:offset] = '1'
          subject[:offset].should be_nil
          subject[:skip].should == 1
        end
      end

      context ":sort" do
        setup   { @options = OptionsHash.new }
        subject { @options }

        should "default to nil" do
          subject[:sort].should be_nil
        end

        should "work with natural order ascending" do
          subject[:sort] = {'$natural' => 1}
          subject[:sort].should == {'$natural' => 1}
        end

        should "work with natural order descending" do
          subject[:sort] = {'$natural' => -1}
          subject[:sort].should =={'$natural' => -1}
        end

        should "convert single ascending field (string)" do
          subject[:sort] = 'foo asc'
          subject[:sort].should == [['foo', 1]]

          subject[:sort] = 'foo ASC'
          subject[:sort].should == [['foo', 1]]
        end

        should "convert single descending field (string)" do
          subject[:sort] = 'foo desc'
          subject[:sort].should == [['foo', -1]]

          subject[:sort] = 'foo DESC'
          subject[:sort].should == [['foo', -1]]
        end

        should "convert multiple fields (string)" do
          subject[:sort] = 'foo desc, bar asc'
          subject[:sort].should == [['foo', -1], ['bar', 1]]
        end

        should "convert multiple fields and default no direction to ascending (string)" do
          subject[:sort] = 'foo desc, bar, baz'
          subject[:sort].should == [['foo', -1], ['bar', 1], ['baz', 1]]
        end

        should "convert symbol" do
          subject[:sort] = :name
          subject[:sort] = [['name', 1]]
        end

        should "convert operator" do
          subject[:sort] = :foo.desc
          subject[:sort].should == [['foo', -1]]
        end

        should "convert array of operators" do
          subject[:sort] = [:foo.desc, :bar.asc]
          subject[:sort].should == [['foo', -1], ['bar', 1]]
        end

        should "convert array of symbols" do
          subject[:sort] = [:first_name, :last_name]
          subject[:sort] = [['first_name', 1], ['last_name', 1]]
        end

        should "work with array and one string element" do
          subject[:sort] = ['foo, bar desc']
          subject[:sort].should == [['foo', 1], ['bar', -1]]
        end

        should "work with array of single array" do
          subject[:sort] = [['foo', -1]]
          subject[:sort].should == [['foo', -1]]
        end

        should "work with array of multiple arrays" do
          subject[:sort] = [['foo', -1], ['bar', 1]]
          subject[:sort].should == [['foo', -1], ['bar', 1]]
        end

        should "compact nil values in array" do
          subject[:sort] = [nil, :foo.desc]
          subject[:sort].should == [['foo', -1]]
        end

        should "convert array with mix of values" do
          subject[:sort] = [:foo.desc, 'bar']
          subject[:sort].should == [['foo', -1], ['bar', 1]]
        end

        should "convert id to _id" do
          subject[:sort] = [:id.asc]
          subject[:sort].should == [['_id', 1]]
        end

        should "convert string with $natural correctly" do
          subject[:sort] = '$natural desc'
          subject[:sort].should == [['$natural', -1]]
        end
      end
    end
  end

  context "#merge" do
    setup do
      @o1 = OptionsHash.new(:skip => 5, :sort => :name)
      @o2 = OptionsHash.new(:limit => 10, :skip => 15)
      @merged = @o1.merge(@o2)
    end

    should "override options in first with options in second" do
      @merged.should == OptionsHash.new(:limit => 10, :skip => 15, :sort => :name)
    end

    should "return new instance and not change either of the merged" do
      @o1[:skip].should == 5
      @o2[:sort].should be_nil
      @merged.should_not equal(@o1)
      @merged.should_not equal(@o2)
    end
  end

  context "#merge!" do
    setup do
      @o1 = OptionsHash.new(:skip => 5, :sort => :name)
      @o2 = OptionsHash.new(:limit => 10, :skip => 15)
      @merged = @o1.merge!(@o2)
    end

    should "override options in first with options in second" do
      @merged.should == OptionsHash.new(:limit => 10, :skip => 15, :sort => :name)
    end

    should "just update the first" do
      @merged.should equal(@o1)
    end
  end
end