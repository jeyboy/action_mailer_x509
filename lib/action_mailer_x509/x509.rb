require 'openssl'

class DecodeError < Exception; end
class VerificationError < Exception; end
class InitializationError < Exception; end

module ActionMailerX509
  class X509
    attr_accessor :certificate, :cipher, :rsa_key, :certificate_store
    class_attribute :accept_decoding
    self.accept_decoding = true

    def initialize(attrs = {})
      attrs.symbolize_keys!
      attrs.reverse_merge!(pass_phrase: '', cipher_type_str: 'des')

      p12_obj = as_p12(prepare_value(attrs[:certificate]), attrs[:pass_phrase])

      if p12_obj
        @certificate = p12_obj.certificate
        @rsa_key = p12_obj.key
      elsif attrs[:certificate] and attrs[:rsa_key]
        @certificate = OpenSSL::X509::Certificate.new(prepare_value(attrs[:certificate]))
        @rsa_key = OpenSSL::PKey::RSA.new(prepare_value(attrs[:rsa_key]), attrs[:pass_phrase])
      elsif attrs[:certificate]
        @certificate = OpenSSL::X509::Certificate.new(prepare_value(attrs[:certificate]))

        begin
          @rsa_key = OpenSSL::PKey::RSA.new(prepare_value(attrs[:certificate]), attrs[:pass_phrase])
        rescue
          @rsa_key = OpenSSL::PKey::RSA.new(@certificate.public_key)
          @accept_decoding = false
        end
      else
        raise Exception.new('Wrong configuration')
      end

      @cipher = OpenSSL::Cipher.new(attrs[:cipher_type_str])

      @certificate_store = OpenSSL::X509::Store.new
      @certificate_store.add_cert(certificate)
    end

    def encode(text)
      if rsa_key.public?
        write Base64.encode64(rsa_key.public_encrypt(text))
      else
        write OpenSSL::PKCS7.encrypt([certificate], text, cipher)
        #OpenSSL::PKCS7.encrypt([certificate], text, cipher, OpenSSL::PKCS7::BINARY)
      end
    end

    def decode(encrypted_text)
      pkcs7 = read(encrypted_text)
      pkcs7.decrypt(@rsa_key, certificate)
    rescue => e
      raise DecodeError.new(e.message)
    end

    def sign(text)
      if rsa_key.public?
        write rsa_key.sign(OpenSSL::Digest::SHA1.new, text)
      else
        write OpenSSL::PKCS7.sign(certificate, rsa_key, text, [], sign_flags)
      end
    end

    def verify(text)
      #set the signer's certificates are not chain verified.
      result = read(text).verify(nil, @certificate_store, nil, OpenSSL::PKCS7::NOVERIFY)
      result ? read(text).data : raise(VerificationError.new('Verification failed !!!'))
    rescue => e
      result = read(text)
      result ? read(text).data : raise(VerificationError.new('Verification failed !!!'))
      rescue => ee
        raise VerificationError.new(ee.message)
    end

    protected
      def as_p12(cert, pass)
        OpenSSL::PKCS12.new(prepare_value(cert), pass) rescue nil
      end

      def sign_flags
        #OpenSSL::PKCS7::NOCERTS
        #OpenSSL::PKCS7::DETACHED
        #OpenSSL::PKCS7::BINARY
        #OpenSSL::PKCS7::NOATTR
        #OpenSSL::PKCS7::NOSMIMECAP
        OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY #| OpenSSL::PKCS7::NOATTR
      end

      def write(pcks7)
        OpenSSL::PKCS7::write_smime pcks7
      end

      def read(text)
        OpenSSL::PKCS7.read_smime(text) rescue OpenSSL::PKCS7.new(text)
      end

    private
      def construct_pcks7(text)
        pkcs7 = OpenSSL::PKCS7.new
        pkcs7.add_data(text)
        pkcs7.add_signer(OpenSSL::PKCS7::Signer.new(certificate, rsa_key, OpenSSL::Digest::SHA512.new))

        #OpenSSL::PKCS7::Signer(cert, key, digest)
      end

      def prepare_value(attr)
        case attr.class.name
          when 'String'
            attr
          when 'Pathname'
            File::read(attr)
          when 'File'
            attr.read
          else raise Exception.new('Wrong param type')
        end
      end
  end
end
