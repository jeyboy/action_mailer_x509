require 'action_mailer_x509/configuration_part'

class SignConfigurationPart < ConfigurationPart
  def valid?
    get_processor.sign('test').present? rescue false
  end
end