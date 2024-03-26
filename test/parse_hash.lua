-- luaorm$ luajit test/parse_hash.lua


local function parse_hash (input)
  local hash_algorithm = input:match("with%-(.-)$")
  if hash_algorithm then 
    return (hash_algorithm:lower():gsub("[/-]", "_"))
  end
  hash_algorithm = input:match(".*%-(.-)$")
  if hash_algorithm then 
    return (hash_algorithm:lower():gsub("[/-]", "_"))
  end
end

-- Example usage:
local examples = {
  "RSA-SHA256",
  "id-rsassa-pkcs1-v1_5-with-sha3-512",
  "RSA-SHA512/224",
  "RSA-MD5",
  "RSA-SHA384"
}

for _, example in ipairs(examples) do
  print(example .. " -> " .. parse_hash(example))
end
