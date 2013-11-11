require 'action_mailer_x509/security_object'
require 'action_mailer_x509/sign_configuration_part'
require 'action_mailer_x509/crypt_configuration_part'

class Configuration
  class_attribute :sign_obj
  class_attribute :crypt_obj

  class_attribute :sign_enable
  self.sign_enable = false

  class_attribute :crypt_enable
  self.crypt_enable = false

  def proceed_settings(params)
    params.symbolize_keys!
    params.reverse_merge!(path: ActionMailerX509.default_certs_path || Pathname.new('')) unless @sign_obj

    @sign_enable = params[:sign_enable] if params.has_key?(:sign_enable)
    @crypt_enable = params[:crypt_enable] if params.has_key?(:crypt_enable)

    if @sign_enable
      @sign_obj ||= ::SignConfigurationPart.new
      raise Exception.new('Params must contain sign attributes') unless params.has_key?(:sing) || params.has_key?(:certificate)
    end

    if @crypt_enable
      @crypt_obj ||= ::CryptConfigurationPart.new
      raise Exception.new('Params must contain crypt attributes') unless params.has_key?(:crypt) || params.has_key?(:certificate)
    end

    if params.has_key?(:certificate) || params.has_key?(:key)
      @sign_obj.proceed_settings(params.slice(*(params.keys & [:path, :certificate, :key, :passphrase]))) if @sign_obj
      @crypt_obj.proceed_settings(params.slice(*(params.keys & [:path, :certificate, :key, :cipher, :passphrase]))) if @crypt_obj
    else
      if @sign_obj && params.has_key?(:sign)
        params[:sign].reverse_merge!(path: params[:path]) unless @sign_obj
        @sign_obj.proceed_settings(params[:sign].slice(*(params[:sign].keys & [:path, :certificate, :key, :passphrase])))
      end

      if @crypt_obj && params.has_key?(:crypt)
        params[:crypt].reverse_merge!(path: params[:path]) unless @crypt_obj
        @crypt_obj.proceed_settings(params[:crypt].slice(*(params[:crypt].keys & [:path, :certificate, :key, :cipher, :passphrase])))
      end
    end
  end

  def initialize(params = {})
    proceed_settings(params)
  end

  def valid?
    sign_enable == sign_obj.valid? && crypt_enable == crypt_obj.valid?
  end
end