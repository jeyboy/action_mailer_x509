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
    ActionMailerX509::X509.new(crypt_configuration)
  end

  def get_signer
    ActionMailerX509::X509.new(sign_configuration)
  end

  protected
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