$d = Deferred('vault_get::cert_token',['https://vault.local:8200'])

node default {
  notify { "Vault Token":
    message => "Vault Token was ${d.unwrap}",
  }
}
