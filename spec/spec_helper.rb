require 'rubygems'
require 'bundler/setup'
require 'active_support/all'
require 'action_mailer'
require 'action_mailer_x509'
require 'action_mailer_x509/x509'
require 'action_mailer_x509/security_object'
require 'action_mailer_x509/configuration'
require 'models/notifier'
require 'default_data'

RSpec.configure do |config|

end

def get_config
  ActionMailerX509.get_configuration :test
end

def add_none_config
  ActionMailerX509.default_certs_path = "#{File.dirname(__FILE__)}/../certs"

  attrs = {
      sign_enable: false,
      crypt_enable: false
  }

  ActionMailerX509.add_configuration :none, attrs
end

def add_config(sign = true, crypt = true, p12 = false)
  ActionMailerX509.default_certs_path = "#{File.dirname(__FILE__)}/../certs"

  attrs = {
      sign_enable: sign,
      crypt_enable: crypt,
      passphrase: 'hisp'
  }

  if p12
    attrs.merge!(cert_p12: 'cert-name.p12')
  else
    attrs.merge!(cert: 'ca.crt',
                 key: 'ca.key'
    )
  end

  ActionMailerX509.add_configuration :test, attrs
end

def add_usual_cert_as_p12_config
  ActionMailerX509.default_certs_path = "#{File.dirname(__FILE__)}/../certs"

  attrs = {
      sign_enable: true,
      crypt_enable: true,
      passphrase: 'hisp'
  }

  attrs.merge(cert_p12: 'ca.crt')
  ActionMailerX509.add_configuration :test, attrs
end

def set_config_param(args={})
  config = ActionMailerX509.get_configuration :test
  args.each_pair do |k, v|
    config.send "#{k}=", v
  end
end