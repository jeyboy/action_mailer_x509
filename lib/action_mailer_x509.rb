require 'action_mailer_x509/railtie' if defined?(Rails)
require 'action_mailer_x509/x509'
require 'action_mailer_x509/configuration'
require 'openssl'
require 'overrides/action_mailer/base'
require 'overrides/mail/message'

module ActionMailerX509
  mattr_reader :configurations

  mattr_accessor :default_configuration

  mattr_accessor :default_certs_path

  class << self
    def settings
      yield self
    end

    def configurations
      @configurations ||= {}
    end

    def add_configuration(name, params = {})
      configurations[name.to_sym] = Configuration.new(params)
    end

    def update_configuration(name, params = {})
      configurations[name.to_sym].try(:proceed_settings, params)
    end

    def get_configuration(name)
      configurations[(name || ActionMailerX509.default_configuration).try :to_sym]
    end

    def default_certs_path=(path)
      @@default_certs_path = Pathname.new(path)
    end
  end
end
