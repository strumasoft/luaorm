-- luaorm$ luajit test/orm_postgresql.lua
-- luaorm$ luajit test/orm_postgresql.lua <n>
-- luaorm$ luajit test/orm_postgresql.lua 5


local persistence = require "util.persistence"
local luaorm = require "rocky.luaorm"
local types = require "test.types"

-- luajit test/ormpostgresql.lua 1
local rdbms, index = "postgresql", nil
if tonumber(arg[1]) then index = tonumber(arg[1]) end

-- make db and op global to access it from the tests.lua
-- require rocky.socket to overwrite the global ngx reference
-- do not assign to .ssl = {} if you don't need to
db = luaorm.connect({
  driver = function ()
    require("rocky.socket").ssl = {
      mode = "client",
      protocol = "any", --"tlsv1_3",
      key = "./cert_key.pem",
      certificate = "./cert.pem",
      options = {"all"},
    }
    return require "rocky.postgresql"
  end,
  types = types,
  usePreparedStatement = true,
  debugDB = true,
  rdbms = rdbms, 
  host = "127.0.0.1",
  port = 5432,
  database = "demo",
  user = "demo",
  password = "demo",
  charset = "utf8",
  max_packet_size = 1024 * 1024,
  ssl = true
})
op = db:operators()

persistence.store("./test/types_.lua", luaorm.build(types, "postgresql"))

local tests = require "test.tests"
if index then
  print("--" .. index .. "--")
  local ok, res = pcall(tests[index])
  if not ok then print(res) end
else
  for k,v in pairs(tests) do
    print("--" .. k .. "--")
    local ok, res = pcall(v)
    if not ok then print(res); return end
  end
end

print("\n\n\n" .. "-- sql executed > close --")
local ok, err = db:close()
if not ok then
  print("failed to close: ", err)
  return
end