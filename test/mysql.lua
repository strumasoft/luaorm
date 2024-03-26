-- luaorm$ luajit test/mysql.lua


-- require rocky.socket to overwrite the global ngx reference
-- do not assign to .ssl = {} if you don't need to
require("rocky.socket").ssl = {
  mode = "client",
  protocol = "any", --"tlsv1_3",
  key = "./cert_key.pem",
  certificate = "./cert.pem",
  options = {"all"}
}
local driver = require "resty.mysql"


local db, err = driver:new()
if not db then
  ngx.say("failed to instantiate driver: ", err)
  return
end

db:set_timeout(1000) -- 1 sec

local ok, err, errcode, sqlstate = db:connect{
  host = "127.0.0.1",
  port = 3306,
  database = "demo",
  user = "demo",
  password = "demo",
  charset = "utf8",
  max_packet_size = 1024 * 1024,
  ssl = false
}

if not ok then
  ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
  return
end

ngx.say("connected to db.")

local res, err, errcode, sqlstate =
  db:query([[
  CREATE TABLE IF NOT EXISTS Persons (
    PersonID int,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
  );  
  ]])
if not res then
  ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
  return
end

ngx.say("sql executed > close")

local ok, err = db:close()
if not ok then
  ngx.say("failed to close: ", err)
  return
end
                