require 'helper'

describe Plucky::Query do
  before do
    @chris      = BSON::OrderedHash['_id', 'chris', 'age', 26, 'name', 'Chris']
    @steve      = BSON::OrderedHash['_id', 'steve', 'age', 29, 'name', 'Steve']
    @john       = BSON::OrderedHash['_id', 'john',  'age', 28, 'name', 'John']
    @collection = DB['users']
    @collection.insert(@chris)
    @collection.insert(@steve)
    @collection.insert(@john)
  end

  context "#initialize" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "defaults options to options hash" do
      @query.options.should be_instance_of(Plucky::OptionsHash)
    end

    it "defaults criteria to criteria hash" do
      @query.criteria.should be_instance_of(Plucky::CriteriaHash)
    end
  end

  context "#initialize_copy" do
    before do
      @original = described_class.new(@collection)
      @cloned   = @original.clone
    end

    it "duplicates options" do
      @cloned.options.should_not equal(@original.options)
    end

    it "duplicates criteria" do
      @cloned.criteria.should_not equal(@original.criteria)
    end
  end

  context "#[]=" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "sets key on options for option" do
      subject[:skip] = 1
      subject[:skip].should == 1
    end

    it "sets key on criteria for criteria" do
      subject[:foo] = 'bar'
      subject[:foo].should == 'bar'
    end
  end

  context "#find_each" do
    it "returns a cursor" do
      cursor = described_class.new(@collection).find_each
      cursor.should be_instance_of(Mongo::Cursor)
    end

    it "works with and normalize criteria" do
      cursor = described_class.new(@collection).find_each(:id.in => ['john'])
      cursor.to_a.should == [@john]
    end

    it "works with and normalize options" do
      cursor = described_class.new(@collection).find_each(:order => :name.asc)
      cursor.to_a.should == [@chris, @john, @steve]
    end

    it "yields elements to a block if given" do
      yielded_elements = Set.new
      described_class.new(@collection).find_each { |doc| yielded_elements << doc }
      yielded_elements.should == [@chris, @john, @steve].to_set
    end

    it "is Ruby-like and returns a reset cursor if a block is given" do
      cursor = described_class.new(@collection).find_each {}
      cursor.should be_instance_of(Mongo::Cursor)
      cursor.next.should be_instance_of(BSON::OrderedHash)
    end
  end

  context "#find_one" do
    it "works with and normalize criteria" do
      described_class.new(@collection).find_one(:id.in => ['john']).should == @john
    end

    it "works with and normalize options" do
      described_class.new(@collection).find_one(:order => :age.desc).should == @steve
    end
  end

  context "#find" do
    before do
      @query = described_class.new(@collection)
    end
    subject { @query }

    it "works with single id" do
      @query.find('chris').should == @chris
    end

    it "works with multiple ids" do
      @query.find('chris', 'john').should == [@chris, @john]
    end

    it "works with array of one id" do
      @query.find(['chris']).should == [@chris]
    end

    it "works with array of ids" do
      @query.find(['chris', 'john']).should == [@chris, @john]
    end

    it "ignores those not found" do
      @query.find('john', 'frank').should == [@john]
    end

    it "returns nil for nil" do
      @query.find(nil).should be_nil
    end

    it "returns nil for *nil" do
      @query.find(*nil).should be_nil
    end

    it "normalizes if using object id" do
      id = @collection.insert(:name => 'Frank')
      @query.object_ids([:_id])
      doc = @query.find(id.to_s)
      doc['name'].should == 'Frank'
    end
  end

  context "#per_page" do
    it "defaults to 25" do
      described_class.new(@collection).per_page.should == 25
    end

    it "is changeable and chainable" do
      query = described_class.new(@collection)
      query.per_page(10).per_page.should == 10
    end
  end

  context "#paginate" do
    before do
      @query = described_class.new(@collection).sort(:age).per_page(1)
    end
    subject { @query }

    it "defaults to page 1" do
      subject.paginate.should == [@chris]
    end

    it "works with other pages" do
      subject.paginate(:page => 2).should == [@john]
      subject.paginate(:page => 3).should == [@steve]
    end

    it "works with string page number" do
      subject.paginate(:page => '2').should == [@john]
    end

    it "allows changing per_page" do
      subject.paginate(:per_page => 2).should == [@chris, @john]
    end

    it "decorates return value" do
      docs = subject.paginate
      docs.should respond_to(:paginator)
      docs.should respond_to(:total_entries)
    end

    it "does not modify the original query" do
      subject.paginate(:name => 'John')
      subject[:page].should     be_nil
      subject[:per_page].should be_nil
      subject[:name].should     be_nil
    end

    context "with options" do
      before do
        @result = @query.sort(:age).paginate(:age.gt => 27, :per_page => 10)
      end
      subject { @result }

      it "only returns matching" do
        subject.should == [@john, @steve]
      end

      it "correctly counts matching" do
        subject.total_entries.should == 2
      end
    end
  end

  context "#all" do
    it "works with no arguments" do
      docs = described_class.new(@collection).all
      docs.size.should == 3
      docs.should include(@john)
      docs.should include(@steve)
      docs.should include(@chris)
    end

    it "works with and normalize criteria" do
      docs = described_class.new(@collection).all(:id.in => ['steve'])
      docs.should == [@steve]
    end

    it "works with and normalize options" do
      docs = described_class.new(@collection).all(:order => :name.asc)
      docs.should == [@chris, @john, @steve]
    end

    it "does not modify original query object" do
      query = described_class.new(@collection)
      query.all(:name => 'Steve')
      query[:name].should be_nil
    end
  end

  context "#first" do
    it "works with and normalize criteria" do
      described_class.new(@collection).first(:age.lt => 29).should == @chris
    end

    it "works with and normalize options" do
      described_class.new(@collection).first(:age.lte => 29, :order => :name.desc).should == @steve
    end

    it "does not modify original query object" do
      query = described_class.new(@collection)
      query.first(:name => 'Steve')
      query[:name].should be_nil
    end
  end

  context "#last" do
    it "works with and normalize criteria" do
      described_class.new(@collection).last(:age.lte => 29, :order => :name.asc).should == @steve
    end

    it "works with and normalize options" do
      described_class.new(@collection).last(:age.lte => 26, :order => :name.desc).should == @chris
    end

    it "does not modify original query object" do
      query = described_class.new(@collection)
      query.last(:name => 'Steve')
      query[:name].should be_nil
    end
  end

  context "#count" do
    it "works with no arguments" do
      described_class.new(@collection).count.should == 3
    end

    it "works with and normalize criteria" do
      described_class.new(@collection).count(:age.lte => 28).should == 2
    end

    it "does not modify original query object" do
      query = described_class.new(@collection)
      query.count(:name => 'Steve')
      query[:name].should be_nil
    end
  end

  context "#size" do
    it "works just like count without options" do
      described_class.new(@collection).size.should == 3
    end
  end

  context "#distinct" do
    before do
      # same age as John
      @mark = BSON::OrderedHash['_id', 'mark', 'age', 28, 'name', 'Mark']
      @collection.insert(@mark)
    end

    it "works with just a key" do
      described_class.new(@collection).distinct(:age).sort.should == [26, 28, 29]
    end

    it "works with criteria" do
      described_class.new(@collection).distinct(:age, :age.gt => 26).sort.should == [28, 29]
    end

    it "does not modify the original query object" do
      query = described_class.new(@collection)
      query.distinct(:age, :name => 'Mark').should == [28]
      query[:name].should be_nil
    end
  end

  context "#remove" do
    it "works with no arguments" do
      lambda { described_class.new(@collection).remove }.should change { @collection.count }.by(-3)
    end

    it "works with and normalize criteria" do
      lambda { described_class.new(@collection).remove(:age.lte => 28) }.should change { @collection.count }
    end

    it "works with options" do
      lambda { described_class.new(@collection).remove({:age.lte => 28}, :safe => true) }.should change { @collection.count }
    end

    it "does not modify original query object" do
      query = described_class.new(@collection)
      query.remove(:name => 'Steve')
      query[:name].should be_nil
    end
  end

  context "#update" do
    before do
      @query = described_class.new(@collection).where('_id' => 'john')
    end

    it "works with document" do
      @query.update('$set' => {'age' => 29})
      doc = @query.first('_id' => 'john')
      doc['age'].should be(29)
    end

    it "works with document and driver options" do
      @query.update({'$set' => {'age' => 30}}, :multi => true)
      @query.each do |doc|
        doc['age'].should be(30)
      end
    end
  end

  context "#[]" do
    it "returns value if key in criteria (symbol)" do
      described_class.new(@collection, :count => 1)[:count].should == 1
    end

    it "returns value if key in criteria (string)" do
      described_class.new(@collection, :count => 1)['count'].should == 1
    end

    it "returns nil if key not in criteria" do
      described_class.new(@collection)[:count].should be_nil
    end
  end

  context "#[]=" do
    before { @query = described_class.new(@collection) }

    it "sets the value of the given criteria key" do
      @query[:count] = 1
      @query[:count].should == 1
    end

    it "overwrites value if key already exists" do
      @query[:count] = 1
      @query[:count] = 2
      @query[:count].should == 2
    end

    it "normalizes value" do
      now = Time.now
      @query[:published_at] = now
      @query[:published_at].should == now.utc
    end
  end

  context "#fields" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      subject.fields(:name).first(:id => 'john').keys.should == ['_id', 'name']
    end

    it "returns new instance of query" do
      new_query = subject.fields(:name)
      new_query.should_not equal(subject)
      subject[:fields].should be_nil
    end

    it "works with hash" do
      subject.fields(:name => 0).
        first(:id => 'john').keys.sort.
        should == ['_id', 'age']
    end
  end

  context "#ignore" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "includes a list of keys to ignore" do
      new_query = subject.ignore(:name).first(:id => 'john')
      new_query.keys.should == ['_id', 'age']
    end
  end

  context "#only" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "includes a list of keys with others excluded" do
      new_query = subject.only(:name).first(:id => 'john')
      new_query.keys.should == ['_id', 'name']
    end

  end

  context "#skip" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      subject.skip(2).all(:order => :age).should == [@steve]
    end

    it "sets skip option" do
      subject.skip(5).options[:skip].should == 5
    end

    it "overrides existing skip" do
      subject.skip(5).skip(10).options[:skip].should == 10
    end

    it "returns nil for nil" do
      subject.skip.options[:skip].should be_nil
    end

    it "returns new instance of query" do
      new_query = subject.skip(2)
      new_query.should_not equal(subject)
      subject[:skip].should be_nil
    end

    it "aliases to offset" do
      subject.offset(5).options[:skip].should == 5
    end
  end

  context "#limit" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      subject.limit(2).all(:order => :age).should == [@chris, @john]
    end

    it "sets limit option" do
      subject.limit(5).options[:limit].should == 5
    end

    it "overwrites existing limit" do
      subject.limit(5).limit(15).options[:limit].should == 15
    end

    it "returns new instance of query" do
      new_query = subject.limit(2)
      new_query.should_not equal(subject)
      subject[:limit].should be_nil
    end
  end

  context "#sort" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      subject.sort(:age).all.should == [@chris, @john, @steve]
      subject.sort(:age.desc).all.should == [@steve, @john, @chris]
    end

    it "works with symbol operators" do
      subject.sort(:foo.asc, :bar.desc).options[:sort].should == [['foo', 1], ['bar', -1]]
    end

    it "works with string" do
      subject.sort('foo, bar desc').options[:sort].should == [['foo', 1], ['bar', -1]]
    end

    it "works with just a symbol" do
      subject.sort(:foo).options[:sort].should == [['foo', 1]]
    end

    it "works with symbol descending" do
      subject.sort(:foo.desc).options[:sort].should == [['foo', -1]]
    end

    it "works with multiple symbols" do
      subject.sort(:foo, :bar).options[:sort].should == [['foo', 1], ['bar', 1]]
    end

    it "returns new instance of query" do
      new_query = subject.sort(:name)
      new_query.should_not equal(subject)
      subject[:sort].should be_nil
    end

    it "is aliased to order" do
      subject.order(:foo).options[:sort].should       == [['foo', 1]]
      subject.order(:foo, :bar).options[:sort].should == [['foo', 1], ['bar', 1]]
    end
  end

  context "#reverse" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      subject.sort(:age).reverse.all.should == [@steve, @john, @chris]
    end

    it "does not error if no sort provided" do
      expect {
        subject.reverse
      }.to_not raise_error
    end

    it "reverses the sort order" do
      subject.sort('foo asc, bar desc').
        reverse.options[:sort].should == [['foo', -1], ['bar', 1]]
    end

    it "returns new instance of query" do
      sorted_query = subject.sort(:name)
      new_query = sorted_query.reverse
      new_query.should_not equal(sorted_query)
      sorted_query[:sort].should == [['name', 1]]
    end
  end

  context "#amend" do
    it "normalizes and update options" do
      described_class.new(@collection).amend(:order => :age.desc).options[:sort].should == [['age', -1]]
    end

    it "works with simple stuff" do
      described_class.new(@collection).
        amend(:foo => 'bar').
        amend(:baz => 'wick').
        criteria.source.should eq(:foo => 'bar', :baz => 'wick')
    end
  end

  context "#where" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      subject.where(:age.lt => 29).where(:name => 'Chris').all.should == [@chris]
    end

    it "works with literal regexp" do
      subject.where(:name => /^c/i).all.should == [@chris]
    end

    it "updates criteria" do
      subject.
        where(:moo => 'cow').
        where(:foo => 'bar').
        criteria.source.should eq(:foo => 'bar', :moo => 'cow')
    end

    it "gets normalized" do
      subject.
        where(:moo => 'cow').
        where(:foo.in => ['bar']).
        criteria.source.should eq(:moo => 'cow', :foo => {:$in => ['bar']})
    end

    it "normalizes merged criteria" do
      subject.
        where(:foo => 'bar').
        where(:foo => 'baz').
        criteria.source.should eq(:foo => {:$in => %w[bar baz]})
    end

    it "returns new instance of query" do
      new_query = subject.where(:name => 'John')
      new_query.should_not equal(subject)
      subject[:name].should be_nil
    end
  end

  context "#filter" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works the same as where" do
      subject.filter(:age.lt => 29).filter(:name => 'Chris').all.should == [@chris]
    end
  end

  context "#empty?" do
    it "returns true if empty" do
      @collection.remove
      described_class.new(@collection).should be_empty
    end

    it "returns false if not empty" do
      described_class.new(@collection).should_not be_empty
    end
  end

  context "#exists?" do
    it "returns true if found" do
      described_class.new(@collection).exists?(:name => 'John').should be(true)
    end

    it "returns false if not found" do
      described_class.new(@collection).exists?(:name => 'Billy Bob').should be(false)
    end
  end

  context "#exist?" do
    it "returns true if found" do
      described_class.new(@collection).exist?(:name => 'John').should be(true)
    end

    it "returns false if not found" do
      described_class.new(@collection).exist?(:name => 'Billy Bob').should be(false)
    end
  end

  context "#include?" do
    it "returns true if included" do
      described_class.new(@collection).include?(@john).should be(true)
    end

    it "returns false if not included" do
      described_class.new(@collection).include?(['_id', 'frankyboy']).should be(false)
    end
  end

  context "#to_a" do
    it "returns all documents the query matches" do
      described_class.new(@collection).sort(:name).to_a.
        should == [@chris, @john, @steve]

      described_class.new(@collection).where(:name => 'John').sort(:name).to_a.
        should == [@john]
    end
  end

  context "#each" do
    it "iterates through matching documents" do
      docs = []
      described_class.new(@collection).sort(:name).each do |doc|
        docs << doc
      end
      docs.should == [@chris, @john, @steve]
    end

    it "returns a working enumerator" do
      query = described_class.new(@collection)
      query.each.methods.map(&:to_sym).include?(:group_by).should be(true)
      query.each.next.should be_instance_of(BSON::OrderedHash)
    end
  end

  context "enumerables" do
    it "works" do
      query = described_class.new(@collection).sort(:name)
      query.map { |doc| doc['name'] }.should == %w(Chris John Steve)
      query.collect { |doc| doc['name'] }.should == %w(Chris John Steve)
      query.detect { |doc| doc['name'] == 'John' }.should == @john
      query.min { |a, b| a['age'] <=> b['age'] }.should == @chris
    end
  end

  context "#object_ids" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "sets criteria's object_ids" do
      subject.criteria.should_receive(:object_ids=).with([:foo, :bar])
      subject.object_ids(:foo, :bar)
    end

    it "returns current object ids if keys argument is empty" do
      subject.object_ids(:foo, :bar)
      subject.object_ids.should == [:foo, :bar]
    end
  end

  context "#merge" do
    it "overwrites options" do
      query1 = described_class.new(@collection, :skip => 5, :limit => 5)
      query2 = described_class.new(@collection, :skip => 10, :limit => 10)
      new_query = query1.merge(query2)
      new_query.options[:skip].should == 10
      new_query.options[:limit].should == 10
    end

    it "merges criteria" do
      query1 = described_class.new(@collection, :foo => 'bar')
      query2 = described_class.new(@collection, :foo => 'baz', :fent => 'wick')
      new_query = query1.merge(query2)
      new_query.criteria[:fent].should == 'wick'
      new_query.criteria[:foo].should == {:$in => %w[bar baz]}
    end

    it "does not affect either of the merged queries" do
      query1 = described_class.new(@collection, :foo => 'bar', :limit => 5)
      query2 = described_class.new(@collection, :foo => 'baz', :limit => 10)
      new_query = query1.merge(query2)
      query1[:foo].should   == 'bar'
      query1[:limit].should == 5
      query2[:foo].should   == 'baz'
      query2[:limit].should == 10
    end
  end

  context "Criteria/option auto-detection" do
    it "knows :conditions are criteria" do
      query = described_class.new(@collection, :conditions => {:foo => 'bar'})
      query.criteria.source.should eq(:foo => 'bar')
      query.options.keys.should_not include(:conditions)
    end

    {
      :fields     => ['foo'],
      :sort       => [['foo', 1]],
      :hint       => '',
      :skip       => 0,
      :limit      => 0,
      :batch_size => 0,
      :timeout    => 0,
    }.each do |option, value|
      it "knows #{option} is an option" do
        query = described_class.new(@collection, option => value)
        query.options[option].should == value
        query.criteria.keys.should_not include(option)
      end
    end

    it "knows select is an option and remove it from options" do
      query = described_class.new(@collection, :select => 'foo')
      query.options[:fields].should == ['foo']
      query.criteria.keys.should_not include(:select)
      query.options.keys.should_not  include(:select)
    end

    it "knows order is an option and remove it from options" do
      query = described_class.new(@collection, :order => 'foo')
      query.options[:sort].should == [['foo', 1]]
      query.criteria.keys.should_not include(:order)
      query.options.keys.should_not  include(:order)
    end

    it "knows offset is an option and remove it from options" do
      query = described_class.new(@collection, :offset => 0)
      query.options[:skip].should == 0
      query.criteria.keys.should_not include(:offset)
      query.options.keys.should_not  include(:offset)
    end

    it "works with full range of things" do
      query = described_class.new(@collection, {
        :foo    => 'bar',
        :baz    => true,
        :sort   => [['foo', 1]],
        :fields => ['foo', 'baz'],
        :limit  => 10,
        :skip   => 10,
      })
      query.criteria.source.should eq(:foo => 'bar', :baz => true)
      query.options.source.should eq({
        :sort   => [['foo', 1]],
        :fields => ['foo', 'baz'],
        :limit  => 10,
        :skip   => 10,
      })
    end
  end

  it "inspects pretty" do
    inspect = described_class.new(@collection, :baz => 'wick', :foo => 'bar').inspect
    inspect.should == '#<Plucky::Query baz: "wick", foo: "bar">'
  end

  it "delegates simple? to criteria" do
    query = described_class.new(@collection)
    query.criteria.should_receive(:simple?)
    query.simple?
  end

  it "delegates fields? to options" do
    query = described_class.new(@collection)
    query.options.should_receive(:fields?)
    query.fields?
  end

  context "#explain" do
    before  { @query = described_class.new(@collection) }
    subject { @query }

    it "works" do
      explain = subject.where(:age.lt => 28).explain
      explain['cursor'].should == 'BasicCursor'
      explain['nscanned'].should == 3
    end
  end

  context "Transforming documents" do
    before do
      transformer = lambda { |doc| @user_class.new(doc['_id'], doc['name'], doc['age']) }
      @user_class = Struct.new(:id, :name, :age)
      @query = described_class.new(@collection, :transformer => transformer)
    end

    it "works with find_one" do
      result = @query.find_one('_id' => 'john')
      result.should be_instance_of(@user_class)
    end

    it "works with find_each" do
      results = @query.find_each
      results.each do |result|
        result.should be_instance_of(@user_class)
      end
    end
  end
end
