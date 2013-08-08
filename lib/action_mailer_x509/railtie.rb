require 'action_mailer_x509'
require 'rails'
module ActionMailerX509
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/action_mailer_x509.rake'
    end
  end
end
