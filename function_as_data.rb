def mk_db(db)
  -> verb=nil, key=nil do
    extended_time = 60 * 1
    case verb
    when :save
      db[key] = Time.now.to_i
    when :get
      db[key]
    when :delete
      db.delete key
    when :has?
      db.fetch(key, false)
    when :timestamp
      db[key]
    when :extend
      db[key] = Time.now.to_i + extended_time
    else
      '没有这个命令。'
    end
    db
  end
end

db = mk_db({})

db.call :save, :key1
db.call :save, :key2
db.call :save, :key3

p db.() # called without arguments, returen db content
