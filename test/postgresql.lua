-- luaorm$ luajit test/postgresql.lua


-- require rocky.socket to overwrite the global ngx reference
-- do not assign to .ssl = {} if you don't need to
require("rocky.socket").ssl = {
  mode = "client",
  protocol = "any", --"tlsv1_3",
  key = "./cert_key.pem",
  certificate = "./cert.pem",
  options = {"all"},
}
local driver = require "rocky.postgresql"


local db, err = driver:new()
if not db then
  ngx.say("failed to instantiate driver: ", err)
  return
end

db:set_timeout(1000) -- 1 sec

local ok, err, errcode, sqlstate = db:connect{
  host = "127.0.0.1",
  port = 5432,
  database = "demo",
  user = "demo",
  password = "demo",
  charset = "utf8",
  max_packet_size = 1024 * 1024,
  ssl = true
}

if not ok then
  ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
  return
end

ngx.say("connected to db.")

ngx.say("\n\n\n" .. "create table persons..1..2..3")
local res, err, errcode, sqlstate = db:query([[
  DROP TABLE IF EXISTS Persons;
  CREATE TABLE IF NOT EXISTS Persons (
    PersonID int,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
  ); 
  CREATE TABLE IF NOT EXISTS Persons2 (
    PersonID int,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
  ); 
  CREATE TABLE IF NOT EXISTS Persons3 (
    PersonID int,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
  );  
]])
if not res then
  ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
  --return
end

ngx.say("\n\n\n" .. "insert into persons")
res, err, errcode, sqlstate = db:query([[
  INSERT INTO Persons (PersonID, LastName, FirstName, Address, City)
  VALUES
  (1, 'Doe', 'John', 'Main St', 'Anytown'),
  (2, 'Smith', 'Jane', 'Oak St', 'AnotherCity'),
  (3, 'Johnson', 'Robert', 'Elm St', 'SomeCity'),
  (4, 'Brown', 'Alice', 'Pine St', 'DifferentCity'),
  (5, 'Williams', 'David', 'Maple St', 'NewCity'),
  (6, '', '', 'Maple St', 'NewCity');
]])
if not res then
  ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
  --return
end

ngx.say("\n\n\n" .. "query all persons twice")
res, err, errcode, sqlstate = db:query([[
  SELECT * FROM Persons;
  SELECT * FROM Persons;
]])
if not res then
  ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
  --return
else
  ngx.say(ngx.dump(res))
end

ngx.say("\n\n\n" .. "query all persons")
res, err, errcode, sqlstate = db:query([[
  SELECT * FROM Persons;
]])
if not res then
  ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
  --return
else
  ngx.say(ngx.dump(res))
end

ngx.say("\n\n\n" .. "sql executed > close")

local ok, err = db:close()
if not ok then
  ngx.say("failed to close: ", err)
  return
end
