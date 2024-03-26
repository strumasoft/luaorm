-- luaorm$ luajit test/orm.lua


local persistence = require "util.persistence"
local luaorm = require "rocky.luaorm"
local types = require "test.types"

local function printf(s, ...)
  print(string.format(s, ...))
end

local phony = {
  new = function (self)
    return {
      set_timeout = function (self, timeout) printf("[set_timeout] %d", timeout) end,
      connect = function (self, connection) printf("[connect] %s", connection.rdbms); return true end,
      query = function (self, sql) printf("%s", sql) end,
      close = function (self) print("[close]") end,
      read_result = function (self) print("[read_result]") end,
    }
  end
}

-- luajit test/orm.lua mysql 1
-- luajit test/orm.lua postgresql 1
local index
local rdbms = "mysql"
if arg[1] then
  if tonumber(arg[1]) then 
    index = tonumber(arg[1])
  else 
    rdbms = arg[1]
    if tonumber(arg[2]) then index = tonumber(arg[2]) end
  end
end

-- make db and op global to access it from the tests.lua
db = luaorm.connect({
  driver = phony,
  types = types,
  usePreparedStatement = false,
  debugDB = false,
  rdbms = rdbms, 
  host = "127.0.0.1",
  port = 1000,
  database = "demo",
  user = "demo",
  password = "demo",
  charset = "utf8",
  max_packet_size = 1024 * 1024,
  ssl = false
})
op = db:operators()

persistence.store("./test/types_.lua", luaorm.build(types, "mysql"))

local tests = require "test.tests"
if index then
  print("--" .. index .. "--")
  pcall(tests[index]) 
else
  for k,v in pairs(tests) do
    print("--" .. k .. "--")
    local ok, res = pcall(v)
    if not ok then print(res) end
  end
end