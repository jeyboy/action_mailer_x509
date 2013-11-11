require 'action_mailer_x509/configuration_part'

class CryptConfigurationPart < ConfigurationPart
  class_attribute :cipher
  self.cipher = 'des'

  def valid?
    get_processor.encode('test').present? rescue false
  end

  def obj_configuration
    super.merge({ cipher_type_str: cipher })
  end
end