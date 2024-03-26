local print = function (...)
  print("\n" .. ...)
end


local function test1 ()
  db:dropAllTables()
  db:createAllTables()
end


local function test2 ()
  for i=1,100 do
    db:delete{product = {code = "code" ..i}}
  end
  
  for i=1,10 do
    for j=1,10 do
      local id = db:add({product = {code = "code"..((i-1)*10+j), 
        manufacturer = "mnf"..i, origin = "CHINA"}})
    end
  end
  
  local res = db:find({
    product = {code = op.like("code%")}, 
    orderBy = {op.asc("code"), op.asc("id")}
  })
  assert(res and #res == 100)
  
  for i=1,#res do
    res[i].origin = "CHN"
    db:update({product = res[i]})
  end
  
  for i=1,#res do
    print("info:" .. res[i].info)
  end
  
  local res = db:find({product = {origin = op.equal("CHN")}})
  assert(res and #res == 100)
  
  local count = db:count({product = {origin = op.equal("CHN")}})
  assert(#res == count)
  
  for i=1,10 do
    local res = db:find(i, 10, {
      product = {origin = op.equal("CHN")},
      orderBy = {op.asc("code")}
    })
    assert(#res == 10)
  end 
end


local function test3 ()
  print("-- add user1 --")
  local user1 = db:add{user = {
    name = "jelko"
  }}

  print("-- add address1 with user1 --")
  local address1 = db:add{address = {
    user = {user1}, -- array of one is OK
    line1 = "3 Main str",
    line2 = "Apt 2",
    city = "New York",
    postCode = "1000"
  }}

  print("-- add address2 with user1 --")
  local address2 = db:add{address = {
    user = user1,
    line1 = "11 Oxford str",
    line2 = "Apt 5",
    city = "London",
    postCode = "2000"
  }}

  print("-- add address3 with no user --")
  local address3 = db:add{address = {
    user = {}, -- set no user, might be omitted
    line1 = "23 Zebra str",
    line2 = "Apt 15",
    city = "Madrid",
    postCode = "3000"
  }}

  print("-- find all user1 addresses --")
  local res = db:find({user = {
    name = op.equal("jelko")
  }},{
    "addresses"
  })
  for _,u in ipairs(res) do
    assert(#u.addresses == 2)
  end

  print("-- find all user1 addresses 2 --")
  local u1 = db:findOne{user = {
    id = op.equal(user1)
  }}
  assert(#u1.addresses == 2)

  print("-- add user2 --")
  local user2 = db:add{user = {
    name = "gosho"
  }}

  print("-- update user2 with addresses --")
  -- update only user addresses
  local _user2 = db:update{user = {
    id = user2,
    addresses = {address1, address2, address3}
  }}
  assert(user2 == _user2)
  
  print("-- find all user2 addresses --")
  local u2 = db:findOne{user = {
    id = op.equal(user2)
  }}
  assert(#u2.addresses == 3)
  
  print("-- update user2 with NO addresses --")
  db:update{user = {
    id = user2,
    addresses = {} -- remove addresses
  }}
  
  print("-- prove user2 has no addresses --")
  local _u2 = db:findOne{user = {
    id = op.equal(user2)
  }}
  assert(not _u2.addresses)

  print("-- find 1 user starting with 'g' --")
  local gusers = db:find{user = {
    name = op.like("g%")
  }}
  assert(#gusers == 1)
  
  print("-- delete the only g% user --")
  db:delete{user = gusers[1]}

  print("-- prove NO user starting with 'g' --")
  local nogusers = db:find{user = {
    name = op.like("g%")
  }}
  assert(#nogusers == 0)
end


local function test4 ()
  print("-- add address1 --")
  local address1 = db:add{address = {
    line1 = "3 Main str",
    line2 = "Apt 2",
    city = "New York",
    postCode = "1000"
  }}
  local addr1 = db:findOne{address = {
    id = op.equal(address1)
  }}
  assert(not addr1.user)
  assert(addr1.line2 == "Apt 2")

  print("-- add address2 --")
  local address2 = db:add{address = {
    line1 = "3 Main str",
    line2 = "Apt 22",
    city = "New York",
    postCode = "3000"
  }}
  local addr2 = db:findOne{address = {
    id = op.equal(address2)
  }}
  assert(not addr2.user)
  assert(addr2.line2 == "Apt 22")
  
  print("-- add address3 --")
  local address3 = db:add{address = {
    line1 = "33 Main str",
    line2 = "Apt 32",
    city = "New York",
    postCode = "3000"
  }}
  local addr3 = db:findOne{address = {
    id = op.equal(address3)
  }}
  assert(not addr3.user)
  assert(addr3.line2 == "Apt 32")

  print("-- add user1 --")
  local user1Id = db:add{user = {
    name = "user1",
    --addresses = {address1, address2}
    addresses = {address1, addr2}
  }}
  local user1 = db:findOne{user = {
    id = op.equal(user1Id)
    -- ./rocky/luaorm.lua:435: attempt to concatenate field 'operator' (a nil value)
    --id = user1Id
  }}

  print("-- assert user1 and it's addresses --")
  assert(#user1.addresses == 2)
  
  assert(addr1.user and addr1.user.id == user1Id)
  addr1.user = nil -- remove local reference, essentially force fetching next time from DB 
  assert(addr1.user and addr1.user.id == user1Id)
  assert(addr1.user and addr1.user.id == user1Id) -- no fetching from DB
  
  assert(addr2.user and addr2.user.id == user1Id)
  addr2.user = nil  -- remove local reference, essentially force fetching next time from DB
  assert(addr2.user and addr2.user.id == user1Id)
  assert(addr2.user and addr2.user.id == user1Id)  -- no fetching from DB
  
  print("-- update addr1 with user1 --")
  addr1.user = user1Id -- user1
  db:update{address = addr1}

  print("-- update user1 with addresses --")
  user1.addresses = {addr1, address2, addr3}
  db:update{user = user1}

  print("-- find user1 and get addresses --")
  local u1 = db:findOne({user = {
    id = op.equal(user1Id)
  }} 
  --,{"addresses"}
  )
  assert(#u1.addresses == 3)
  
  print("-- update user1 with NO addresses --")
  user1.addresses = {}
  db:update{user = user1}

  print("-- find user1 and get addresses 2 --")
  local u1 = db:findOne({user = {
    id = op.equal(user1Id)
  }} 
  --,{"addresses"}
  )
  assert(not u1.addresses)
end


local function test5 ()
  local pattern = [[', '%s') --]]
  local sql_injection = function (id)
    return db:add{product = {
      info = "sql_injection" .. string.format(pattern, id)
    }}
  end
  
  math.randomseed(os.time())
  local injected_id = math.random(1, 10000)
  
  local ok, orm_id = pcall(sql_injection, injected_id)
  if ok then
    local function find_product ()
      print("-- find product by orm_id --")
      db:find{product = {id = op.equal(orm_id)}}
      print("-- find product in (orm_id, injected_id) --")
      db:find{product = {id = op.inside(injected_id, orm_id)}}
      print("-- find product by pattern of injected_id --")
      db:find{product = {id = op.equal(string.format(pattern, injected_id))}}
    end
    pcall(find_product)
  else
    print("sql injection failed because of wrong syntax due to unpredictability of values order, try one more time")
  end
end


local function test6 ()
  db:find({
      productAttribute = {
          values = {
              products = {
                  categories = {code = op.equal("c1")}
              }
          }
      }
  })
end


local function test7 ()
  db:find({category = {code = op.like('c%')}})
end


local function test8 ()
  db:find({
      category = {
          supercategories = {
              code = op.equal("c1")
          }
      }
  })  
end


local function test9 ()
  db:find({
    product = {}, 
    orderBy = {op.asc("code"), op.asc("id")}
    }, {"categories"})
end


local function test10 ()
  db:find({deliveryMethod = {}}, {
    {name = {locale = locale}},
    {description = {locale = locale}},
  })
  db:find({deliveryMethod = {}}, {
    {name = {locale = locale}},
    {description = {locale = locale}},
  })
end


return { 
  test1, test2, test3, test4, test5, 
  test6, test7, test8, test9, test10,
}