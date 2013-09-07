require 'action_mailer_x509/security_object'

class Configuration
  def initialize(params = {})
    params.symbolize_keys!
    params.each_pair { |k, v| self.send("#{k}=".to_sym, v) }
  end

  class_attribute :sign_enable
  self.sign_enable = false

  class_attribute :crypt_enable
  self.crypt_enable = false

  class_attribute :crypt_cipher
  self.crypt_cipher = 'des'

  class_attribute :certs_path

  class_attribute :sign_cert
  class_attribute :sign_key
  class_attribute :sign_passphrase
  class_attribute :crypt_cert
  class_attribute :crypt_key
  class_attribute :crypt_passphrase

  class_attribute :sign_cert_p12
  class_attribute :crypt_cert_p12

  #Todo: add func sign_demand?, crypt_demand?

  def sign_require?
    sign_enable == true
  end

  def crypt_require?
    crypt_enable == true
  end

  def certs_path
    @certs_path || ActionMailerX509.default_certs_path
  end

  def certs_path=(path)
    @certs_path = Pathname.new(path)
  end

  def sign_cert
    certs_path.join(@sign_cert)
  end

  def sign_cert_p12
    certs_path.join(@sign_cert_p12)
  end

  def sign_key
    certs_path.join(@sign_key)
  end

  def crypt_cert
    certs_path.join(@crypt_cert)
  end

  def crypt_cert_p12
    certs_path.join(@crypt_cert_p12)
  end

  def crypt_key
    certs_path.join(@crypt_key)
  end

  def get_crypter
    #Todo: add check on valid crypt config
    raise Exception.new('Configuration not valid for crypt operations') unless crypt_require?
    ActionMailerX509::X509.new(crypt_configuration)
  end

  def get_signer
    #Todo: add check on valid sign config
    raise Exception.new('Configuration not valid for sign operations') unless sign_require?
    ActionMailerX509::X509.new(sign_configuration)
  end

  def get_certificate_info
    if valid?
      if sign_require? || crypt_require?
        worker = sign_require? ? get_signer : get_crypter

        subject_attrs = worker.certificate.subject.to_a
        subject_attrs = subject_attrs.each_with_object({}) do |attr, obj|
          obj.update(SecurityObject::ATTRS[attr.first] => attr[1])
        end

        {
          from: worker.certificate.not_before,
          to: worker.certificate.not_after,
        }.reverse_merge!(subject_attrs)
      end || {}
    end || {}
  end

  def valid?
    validate_sign && validate_crypt
  end

  protected
    def validate_sign
      if sign_require?
        begin
          get_signer.sign('test')
        rescue
          return false
        end
      end
      true
    end

    def validate_crypt
      if crypt_require?
        begin
          get_crypter.encode('test')
        rescue
          return false
        end
      end
      true
    end

    def key=(key)
      self.crypt_key = key
      self.sign_key = key
    end

    def cert=(cert)
      self.crypt_cert = cert
      self.sign_cert = cert
    end

    def cert_p12=(cert)
      self.crypt_cert_p12 = cert
      self.sign_cert_p12 = cert
    end

    def passphrase=(pass)
      self.crypt_passphrase = pass
      self.sign_passphrase = pass
    end

  private
    def sign_configuration
      conf = {
          pass_phrase: sign_passphrase
      }

      conf.merge!(certificate_p12: sign_cert_p12) if @sign_cert_p12
      conf.merge!(certificate: sign_cert, rsa_key: sign_key) unless @sign_cert_p12
      conf
    end

    def crypt_configuration
      conf = {
          cipher_type_str: crypt_cipher,
          pass_phrase: crypt_passphrase
      }

      conf.merge!(certificate_p12: crypt_cert_p12) if @crypt_cert_p12
      conf.merge!(certificate: crypt_cert, rsa_key: crypt_key) unless @crypt_cert_p12
      conf
    end
end