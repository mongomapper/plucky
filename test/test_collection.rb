require 'helper'

class CollectionTest < Test::Unit::TestCase
  context "Plucky::Collection" do
    include Plucky

    setup do
      @chris      = oh(['_id', 'chris'],  ['age', 26], ['name', 'Chris'])
      @john       = oh(['_id', 'john'],   ['age', 28], ['name', 'John'])
      @steve      = oh(['_id', 'steve'],  ['age', 29], ['name', 'Steve'])
      @collection = Collection.new(DB['users'])
      @collection.insert(:_id => 'john', :name => 'John', :age => 28)
      @collection.insert(:_id => 'steve', :name => 'Steve', :age => 29)
      @collection.insert(:_id => 'chris', :name => 'Chris', :age => 26)
    end

    context "#all" do
      should "work with no arguments" do
        docs = @collection.all
        docs.size.should == 3
        docs.should include(@john)
        docs.should include(@steve)
        docs.should include(@chris)
      end

      should "work with and normalize criteria" do
        docs = @collection.all(:id.in => ['steve'])
        docs.should == [@steve]
      end

      should "work with and normalize options" do
        docs = @collection.all(:order => :name.asc)
        docs.should == [@chris, @john, @steve]
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
        @collection.last(:age.lte => 26, :order => :name.desc).should == @chris
      end
    end

    context "#count" do
      should "work with no arguments" do
        @collection.count.should == 3
      end

      should "work with and normalize criteria" do
        @collection.count(:age.lte => 28).should == 2
      end
    end

    context "#delete" do
      should "work with no arguments" do
        lambda { @collection.delete }.should change { @collection.count }.by(3)
      end

      should "work with and normalize criteria" do
        lambda { @collection.delete(:age.lte => 28) }.should change { @collection.count }
      end
    end

    context "#sort" do
      should "work" do
        @collection.sort(:age).all.should == [@chris, @john, @steve]
        @collection.sort(:age.desc).all.should == [@steve, @john, @chris]
      end
    end

    context "#filter" do
      should "work" do
        @collection.filter(:age.lt => 29).filter(:name => 'Chris').all.should == [@chris]
      end
    end

    context "#skip" do
      should "work" do
        @collection.skip(2).all(:order => :age).should == [@steve]
      end
    end

    context "#limit" do
      should "work" do
        @collection.limit(2).all(:order => :age).should == [@chris, @john]
      end
    end

    context "#fields" do
      should "work" do
        @collection.fields(:name).first(:id => 'john').keys.should == ['_id', 'name']
      end
    end
    
    context "#reverse" do
      should "work" do
        @collection.sort(:age).reverse.all.should == [@steve, @john, @chris]
      end
    end
    
    context "#where" do
      should "work" do
        @collection.where('this.name == "John"').all.should == [@john]
      end
    end
    
    context "#[]" do
      should "work" do
        @collection.filter(:name => 'John')
        @collection[:name].should == 'John'
      end
    end
    
    context "#[]=" do
      should "work" do
        @collection[:name] = 'John'
        @collection.all.should == [@john]
      end
    end
  end
end