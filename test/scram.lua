-- luaorm$ luajit test/scram.lua


local crypto = require "rocky.crypto"
local b64 = crypto.encode_base64
local _b64 = crypto.decode_base64
local XOR = crypto.xor
local Normalize = function (str) return str end


local sha1 = {
  hash = "sha1",
  hmac = "hmac_sha1",
  derive = "pbkdf2_sha1"
}

local sha256 = {
  hash = "sha256",
  hmac = "hmac_sha256",
  derive = "pbkdf2_sha256"
}


local function scram (digest, username, password, c_nonce, s_nonce, salt, i, verifier, original)
  local nonce = c_nonce .. s_nonce
  
  local H = crypto[digest.hash]
  local HMAC = crypto[digest.hmac]
  local Hi = crypto[digest.derive]

  local comparison = {}
  local printf = function (str)
    print(str)
    comparison[#comparison + 1] = str
  end
  
  local gs2_cbind_flag = "n"
  -- gs2-header = gs2-cbind-flag "," [ authzid ] ","
  local gs2_header = gs2_cbind_flag .. "," .. ","
  -- client-first-message-bare = username "," nonce
  local client_first_message_bare = "n=" .. username .. "," .. "r=" .. c_nonce
  -- client-first-message = gs2-header client-first-message-bare
  local client_first_message = gs2_header .. client_first_message_bare

  printf("C: " .. client_first_message)
  
  local server_first_message = "r=" .. nonce .. ",s=" .. salt .. ",i=" .. i
  printf("S: " .. server_first_message)
  
  --[[
  client-final-message-without-proof =
                     channel-binding "," nonce [","
                     extensions]

  client-final-message =
                     client-final-message-without-proof "," proof
  
  channel-binding = "c=" base64
                     ;; base64 encoding of cbind-input.

  cbind-input   = gs2-header [ cbind-data ]
                     ;; cbind-data MUST be present for
                     ;; gs2-cbind-flag of "p" and MUST be absent
                     ;; for "y" or "n".
  ]]
  local client_final_message_without_proof = "c=" .. b64(gs2_header) .. ",r=" .. nonce
  
  local SaltedPassword  = Hi(Normalize(password), _b64(salt), i)
  local ClientKey       = HMAC(SaltedPassword, "Client Key")
  local StoredKey       = H(ClientKey)
  local AuthMessage     = client_first_message_bare .. "," ..
                        server_first_message .. "," ..
                        client_final_message_without_proof
  local ClientSignature = HMAC(StoredKey, AuthMessage)
  local ClientProof     = XOR(ClientKey, ClientSignature)
  local ServerKey       = HMAC(SaltedPassword, "Server Key")
  local ServerSignature = HMAC(ServerKey, AuthMessage)
  
  printf("C: " .. client_final_message_without_proof .. ",p=" .. b64(ClientProof))
  printf("S: " .. "v=" .. b64(ServerSignature))
  
  local ok = verifier == b64(ServerSignature)
  if ok then print("=== verify success ===") else print("=== verify [fail] ===") end
  
  print(original)
  ok = original == table.concat(comparison, '\n')
  if ok then print("=== compare success ===") else print("=== compare [fail] ===") end
end


local function testSHA256 ()
  local username = "user"
  local password = "pencil"
  local c_nonce = "rOprNGfwEbeRWgbNEkqO"
  local s_nonce = "%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0"
  local salt = "W22ZaJ0SNY7soEsUEjb6gQ=="
  local i = 4096
  local verifier = "6rriTRBi23WpRR/wtup+mMhUZUn/dB5nLTJRsjl95G4="
  local original = 
[[C: n,,n=user,r=rOprNGfwEbeRWgbNEkqO
S: r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,s=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096
C: c=biws,r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,p=dHzbZapWIk4jUhN+Ute9ytag9zjfMHgsqmmiz7AndVQ=
S: v=6rriTRBi23WpRR/wtup+mMhUZUn/dB5nLTJRsjl95G4=]]
  
  scram(sha256, username, password, c_nonce, s_nonce, salt, i, verifier, original)
end

local function testSHA1 ()
  local username = "user"
  local password = "pencil"
  local c_nonce = "fyko+d2lbbFgONRv9qkxdawL"
  local s_nonce = "3rfcNHYJY1ZVvWVs7j"
  local salt = "QSXCR+Q6sek8bf92"
  local i = 4096
  local verifier = "rmF9pqV8S7suAoZWja4dJRkFsKQ="
  local original = 
[[C: n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL
S: r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096
C: c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts=
S: v=rmF9pqV8S7suAoZWja4dJRkFsKQ=]]
  
  scram(sha1, username, password, c_nonce, s_nonce, salt, i, verifier, original)
end


print("=== SHA256 ===")
testSHA256()
print("\n=== SHA1 ===")
testSHA1()
