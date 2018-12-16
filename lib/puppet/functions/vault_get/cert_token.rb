Puppet::Functions.create_function(:'vault_get::cert_token') do
  dispatch :cert_token do
    optional_param 'String', :vault_url
  end

  def cert_token(vault_url = nil)
    if vault_url.nil?
      Puppet.debug 'No Vault address was set on function, defaulting to value from VAULT_ADDR env value'
      vault_url = ENV['VAULT_ADDR']
      raise Puppet::Error, 'No vault_url given and VAULT_ADDR env variable not set' if vault_url.nil?
    end

    uri = URI(vault_url)
    # URI is used here to just parse the vault_url into a host string
    # and port; it's possible to generate a URI::Generic when a scheme
    # is not defined, so double check here to make sure at least
    # host is defined.
    raise Puppet::Error, "Unable to parse a hostname from #{vault_url}" unless uri.hostname

    connection = Puppet::Network::HttpPool.http_ssl_instance(uri.host, uri.port)

    token = get_auth_token(connection)

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(token)
  end

  private

  def get_auth_token(connection)
    response = connection.post('/v1/auth/cert/login', '')
    unless response.is_a?(Net::HTTPOK)
      message = "Received #{response.code} response code from vault at #{connection.address} for authentication"
      raise Puppet::Error, append_api_errors(message, response)
    end

    begin
      token = JSON.parse(response.body)['auth']['client_token']
    rescue StandardError
      raise Puppet::Error, 'Unable to parse client_token from vault response'
    end

    raise Puppet::Error, 'No client_token found' if token.nil?

    token
  end

  def append_api_errors(message, response)
    errors = begin
               JSON.parse(response.body)['errors']
             rescue StandardError
               nil
             end
    message << " (api errors: #{errors})" if errors
  end
end
