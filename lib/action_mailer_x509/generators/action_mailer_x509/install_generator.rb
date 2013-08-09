module ActionMailerX509
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../', __FILE__)
      def copy_initializer
        template 'templates/x509_settings.rb', 'config/initializers/x509_settings.rb'
      end
    end
  end
end