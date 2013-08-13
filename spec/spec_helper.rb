require 'rubygems'
require 'bundler/setup'
require 'active_support/all'
require 'action_mailer'
require 'action_mailer_x509'
require 'action_mailer_x509/x509'
require 'models/notifier'

RSpec.configure do |config|

end

def add_config(sign = true, crypt = true)
  ActionMailerX509.add_configuration :test, {
      sign_enable: sign,
      crypt_enable: crypt,
      sign_cert: 'ca.crt',
      sign_key: 'ca.key',
      sign_passphrase: 'hisp',
      crypt_cert: 'ca.crt',
      crypt_key: 'ca.key',
      crypt_passphrase: 'hisp',
      certs_path: "#{File.dirname(__FILE__)}/../certs"
  }
end

def set_config_param(args={})
  config = ActionMailerX509.configurations[:test]
  args.each_pair do |k, v|
    config.send "#{k}=", v
  end
end