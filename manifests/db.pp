include mysql::server

msql::db { "loja":
  schema   => "loja_schema",
  password => "lojasecret",
}
