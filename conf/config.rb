Vines::Config.configure do
  # Set the logging level to debug, info, warn, error, or fatal. The debug
  # level logs all XML sent and received by the server.
  # If you want logging to STDOUT remove the path
  # e.g. `log 'log/vines.log' do` becomes `log do`
  log 'log/vines.log' do
    level :info
  end

  # Set the directory in which to look for virtual hosts' TLS certificates.
  # This is optional and defaults to the conf/certs directory created during
  # `vines init`.
  certs 'conf/certs'

  host 'diaspora' do
    cross_domain_messages true
    accept_self_signed false
    storage 'sql'
  end

  # Configure the client-to-server port. The max_resources_per_account attribute
  # limits how many concurrent connections one user can have to the server.
  client '0.0.0.0', 5222 do
    max_stanza_size 65536
    max_resources_per_account 5
  end

  # Configure the server-to-server port. The max_stanza_size attribute should be
  # much larger than the setting for client-to-server.
  server '0.0.0.0', 5269 do
    max_stanza_size 131072
    blacklist []
  end

  # Configure the built-in HTTP server that serves static files and responds to
  # XEP-0124 BOSH requests. This allows HTTP clients to connect to
  # the XMPP server.
  http '0.0.0.0', 5280 do
    bind '/http-bind'
    max_stanza_size 65536
    max_resources_per_account 5
    root 'public'
    vroute ''
  end
end
