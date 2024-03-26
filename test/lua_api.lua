-- luaorm$ luajit test/lua_api.lua
-- luaorm$ luajit test/lua_api.lua sub
-- luaorm$ luajit test/lua_api.lua gmatch
-- luaorm$ luajit test/lua_api.lua char
-- luaorm$ luajit test/lua_api.lua concat
-- luaorm$ luajit test/lua_api.lua to
-- luaorm$ luajit test/lua_api.lua hex


local text = [[Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]]
local N = 10000000
local M = 1000000
local P = 50000
local string_sub = string.sub
local string_gmatch = string.gmatch
local string_byte = string.byte
local string_char = string.char
local string_format = string.format
local table_concat = table.concat
local _tonumber = tonumber
local _tostring = tostring


-- timebox function --
local function timebox (fn)
  local startTime = os.clock()
  fn()
  local endTime = os.clock()
  return endTime - startTime
end


-- string.sub --
local function sub1 ()
  for n=1,N do
    for i=1, #text-5 do
      local x = text:sub(i, i+5)
    end
  end
end

local function sub2 ()
  for n=1,N do
    for i=1, #text-5 do
      local x = string_sub(text, i, i+5)
    end
  end
end

local function sub3 ()
  for n=1,N do
    for i=1, #text-5 do
      local x = string.sub(text, i, i+5)
    end
  end
end


-- string.gmatch --
local function gmatch1 ()
  for n=1,M do
    for word in text:gmatch("%w+") do
      local x = word
    end
  end
end

local function gmatch2 ()
  for n=1,M do
    for word in string_gmatch(text, "%w+") do
      local x = word
    end
  end
end

local function gmatch3 ()
  for n=1,M do
    for word in string.gmatch(text, "%w+") do
      local x = word
    end
  end
end


-- string.char --
local function char1 ()
  for n=1,N*10 do
    for i=1,100 do
      local x = string_char(i)
    end
  end
end

local function char2 ()
  for n=1,N*10 do
    for i=1,100 do
      local x = string.char(i)
    end
  end
end


-- table.concat --
local function concat1 ()
  local list = {}
  for word in text:gmatch("%w+") do
    list[#list + 1] = word
  end
  for n=1,N do
    local x = table_concat(list, " ")
  end
end

local function concat2 ()
  local list = {}
  for word in text:gmatch("%w+") do
    list[#list + 1] = word
  end
  for n=1,N do
    local x = table.concat(list, " ")
  end
end


-- tonumber & tostring --
local function to1 ()
  for n=1,M*2 do
    for i=1,100 do
      local x = _tonumber("" .. i)
      local y = _tostring(i)
    end
  end
end

local function to2 ()
  for n=1,M*2 do
    for i=1,100 do
      local x = tonumber("" .. i)
      local y = tostring(i)
    end
  end
end


-- hex --
local function decodeHex1(str)
  return (str:gsub('..', function (cc)
    return string_char(_tonumber(cc, 16))
  end))
end
local function encodeHex1(str)
  return (str:gsub('.', function (c)
    return string_format('%02x', string_byte(c))
  end))
end

local function decodeHex2(str)
  return (str:gsub('..', function (cc)
    return string.char(tonumber(cc, 16))
  end))
end
local function encodeHex2(str)
  return (str:gsub('.', function (c)
    return string.format('%02x', string.byte(c))
  end))
end

local function hex1 ()
  for n=1,P do
    local hex = encodeHex1(text)
    local new_text = decodeHex1(hex)
    assert(text == new_text)
  end
end

local function hex2 ()
  for n=1,P do
    local hex = encodeHex2(text)
    local new_text = decodeHex2(hex)
    assert(text == new_text)
  end
end


-- execute tests --
if arg[1] == "sub" then
  print("test string:sub ", timebox(sub1))
  print("test string_sub ", timebox(sub2))
  print("test string.sub ", timebox(sub3))
elseif arg[1] == "gmatch" then
  print("test string:gmatch ", timebox(gmatch1))
  print("test string_gmatch ", timebox(gmatch2))
  print("test string.gmatch ", timebox(gmatch3))
elseif arg[1] == "char" then
  print("test string_char ", timebox(char1))
  print("test string.char ", timebox(char2))
elseif arg[1] == "concat" then
  print("test table_concat ", timebox(concat1))
  print("test table.concat ", timebox(concat2))
elseif arg[1] == "to" then
  print("test _to* ", timebox(to1))
  print("test  to* ", timebox(to2))
elseif arg[1] == "hex" then
  print("test _hex ", timebox(hex1))
  print("test  hex ", timebox(hex2))
else
  local ffffffff1 = string.char(255) .. string.char(255) .. string.char(255) .. string.char(255)
  local ffffffff2 = string.char(255, 255, 255, 255)
  print(encodeHex1(ffffffff1))
  print(encodeHex1(ffffffff2))
  assert(ffffffff1 == ffffffff2)
end