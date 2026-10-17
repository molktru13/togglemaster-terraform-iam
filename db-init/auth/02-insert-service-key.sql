INSERT INTO api_keys (name, key_hash)
VALUES ('evaluation-service-local', '7bec3ce80738989b6532134d8e6edf5e3a4b8c667eff7621158ef51d322a2833')
ON CONFLICT (key_hash) DO NOTHING;
