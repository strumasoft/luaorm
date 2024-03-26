-- hashes: EVP_sha1 | EVP_sha256 | EVP_sha512_256 and so on check crypto.lua headers
-- luaorm$ luajit test/cert.lua new sha3_512
-- luaorm$ luajit test/cert.lua /etc/ssl/certs/ssl-cert-snakeoil.pem


local certificate = require "rocky.certificate"
local crypto = require "rocky.crypto"

local function certification (generate, cert_file, key_file, bits, hash)
  if generate then
    local ok, err = certificate.generate_certificate(cert_file, key_file, bits, hash)
    if ok then
      print("Self-signed certificate and private key generated successfully")
    else
      print("Error generating self-signed certificate: " .. err)
      return
    end
  end
  
  print("Signature Value (DER-encoded):\n" .. certificate.signature_value(cert_file))
  print("Signature Algorithm: " .. certificate.signature_algorithm(cert_file))
  print("Signature Name: " .. certificate.signature_name(cert_file))
  print("Hash Function: EVP_" .. crypto.parse_hash(certificate.signature_name(cert_file)))
end

if arg[1] == "new" then 
  local cert_file = "cert.pem"
  local key_file = "cert_key.pem"
  local bits = 2048
  local hash = arg[2] or "sha256"
  certification(true, cert_file, key_file, bits, hash)
else
  local cert_file = arg[1] or "cert.pem"
  certification(false, cert_file, nil, nil, nil)
end