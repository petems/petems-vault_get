$d = Deferred('vault_get::cert_token')

node default {
  notify { "Vault Token with ENV was":
    message => "Vault Token with ENV was ${d.unwrap}",
  }
}
