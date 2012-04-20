# Plucky

Thin layer over the ruby driver that allows you to quickly grab hold of your data (pluck it!).

## Install

```
gem install plucky
```

## Examples

```ruby
connection = Mongo::Connection.new
db = connection.db('test')
collection = db['users']
collection.remove # clear out the collection

collection.insert({'_id' => 'chris', 'age' => 26, 'name' => 'Chris'})
collection.insert({'_id' => 'steve', 'age' => 29, 'name' => 'Steve'})
collection.insert({'_id' => 'john',  'age' => 28, 'name' => 'John'})

# initialize query with collection
query = Plucky::Query.new(collection)

puts 'Querying'
pp query.where(:name => 'John').first
pp query.first(:name => 'John')
pp query.where(:name => 'John').all
pp query.all(:name => 'John')

puts 'Find by _id'
pp query.find('chris')
pp query.find('chris', 'steve')
pp query.find(['chris', 'steve'])

puts 'Sort'
pp query.sort(:age).all
pp query.sort(:age.asc).all # same as above
pp query.sort(:age.desc).all
pp query.sort(:age).last # steve

puts 'Counting'
pp query.count # 3
pp query.size # 3
pp query.count(:name => 'John')       # 1
pp query.where(:name => 'John').count # 1
pp query.where(:name => 'John').size  # 1

puts 'Distinct'
pp query.distinct(:age) # [26, 29, 28]

puts 'Select only certain fields'
pp query.fields(:age).find('chris')   # {"_id"=>"chris", "age"=>26}
pp query.only(:age).find('chris')     # {"_id"=>"chris", "age"=>26}
pp query.ignore(:name).find('chris')  # {"_id"=>"chris", "age"=>26}

puts 'Pagination, yeah we got that'
pp query.sort(:age).paginate(:per_page => 1, :page => 2)
pp query.sort(:age).per_page(1).paginate(:page => 2)

pp query.sort(:age).limit(2).to_a           # [chris, john]
pp query.sort(:age).skip(1).limit(2).to_a   # [john, steve]
pp query.sort(:age).offset(1).limit(2).to_a # [john, steve]

puts 'Using a cursor'
cursor = query.find_each(:sort => :age) do |doc|
  pp doc
end
pp cursor

puts 'Symbol Operators'
pp query.where(:age.gt => 28).count       # 1 (steve)
pp query.where(:age.lt => 28).count       # 1 (chris)
pp query.where(:age.in => [26, 28]).to_a  # [chris, john]
pp query.where(:age.nin => [26, 28]).to_a  # [steve]

puts 'Removing'
query.remove(:name => 'John')
pp query.count # 2
query.where(:name => 'Chris').remove
pp query.count # 1
query.remove
pp query.count # 0
```

## Help

https://groups.google.com/forum/#!forum/mongomapper

## Contributing

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 John Nunemaker. See LICENSE for details.
