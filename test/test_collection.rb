require 'helper'

class CollectionTest < Test::Unit::TestCase
  context "Plucky::Collection" do
    include Plucky

    setup do
      @john       = oh(['_id', 'john'], ['age', 28], ['name', 'John'])
      @steve      = oh(['_id', 'steve'], ['age', 29], ['name', 'Steve'])
      @collection = Collection.new(DB['users'])
      @collection.insert(:_id => 'john', :name => 'John', :age => 28)
      @collection.insert(:_id => 'steve', :name => 'Steve', :age => 29)
    end

    context "#all" do
      should "work with no arguments" do
        docs = @collection.all
        docs.size.should == 2
        docs.should include(@john)
        docs.should include(@steve)
      end

      should "work with and normalize criteria" do
        docs = @collection.all(:id.ne => 'john')
        docs.should == [@steve]
      end

      should "work with and normalize options" do
        docs = @collection.all(:order => :name.asc)
        docs.should == [@john, @steve]
      end
    end

    context "#first" do
      should "work with and normalize criteria" do
        @collection.first(:age.lt => 29).should == @john
      end

      should "work with and normalize options" do
        @collection.first(:age.lte => 29, :order => :name.desc).should == @steve
      end
    end

    context "#last" do
      should "work with and normalize criteria" do
        @collection.last(:age.lte => 29, :order => :name.asc).should == @steve
      end

      should "work with and normalize options" do
        @collection.last(:age.lte => 29, :order => :name.desc).should == @john
      end
    end
  end
end