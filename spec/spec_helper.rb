require 'rubygems'
require 'bundler/setup'
require 'active_support/all'
require 'action_mailer'
require 'action_mailer_x509'
require 'action_mailer_x509/x509'
require 'models/notifier'

RSpec.configure do |config|

end

def add_config(sign = true, crypt = true, p12 = false)
  ActionMailerX509.default_certs_path = "#{File.dirname(__FILE__)}/../certs"

  attrs = {
      sign_enable: sign,
      crypt_enable: crypt,
      sign_passphrase: 'hisp',
      crypt_passphrase: 'hisp',
  }

  if p12
    attrs.merge!(sign_cert_p12: 'cert-name.p12',
                 crypt_cert_p12: 'cert-name.p12',
    )
  else
    attrs.merge!(sign_cert: 'ca.crt',
                 sign_key: 'ca.key',
                 crypt_cert: 'ca.crt',
                 crypt_key: 'ca.key'
    )
  end

  ActionMailerX509.add_configuration :test, attrs
end

def set_config_param(args={})
  config = ActionMailerX509.configurations[:test]
  args.each_pair do |k, v|
    config.send "#{k}=", v
  end
end