require 'openssl'

class DecodeError < Exception; end
class VerificationError < Exception; end

module ActionMailerX509
  class X509
    attr_accessor :certificate, :cipher, :rsa_key, :certificate_store

    # pass_phrase
    # cipher_type_str
    # certificate and rsa_key or certificate_p12
    def initialize(attrs = {})
      attrs.symbolize_keys!

      attrs.reverse_merge!(pass_phrase: '', cipher_type_str: 'des')
      if attrs[:certificate_p12]
        p12 = OpenSSL::PKCS12.new(prepare_value(attrs[:certificate_p12]), attrs[:pass_phrase])
        @certificate = p12.certificate
        @rsa_key = p12.key
      elsif attrs[:certificate] and attrs[:rsa_key]
        @certificate = OpenSSL::X509::Certificate.new(prepare_value(attrs[:certificate]))
        @rsa_key = OpenSSL::PKey::RSA.new(prepare_value(attrs[:rsa_key]), attrs[:pass_phrase])
      else
        raise Exception.new('Wrong configuration')
      end

      @cipher = OpenSSL::Cipher.new(attrs[:cipher_type_str])

      @certificate_store = OpenSSL::X509::Store.new
      @certificate_store.add_cert(certificate)
    end

    def encode(text)
      write OpenSSL::PKCS7.encrypt([certificate], text, cipher)
      #OpenSSL::PKCS7.encrypt([certificate], text, cipher, OpenSSL::PKCS7::BINARY)
    end

    def decode(encrypted_text)
      pkcs7 = read(encrypted_text)
      pkcs7.decrypt(@rsa_key, certificate)
    rescue => e
      raise DecodeError.new(e.message)
    end

    def sign(text)
      write OpenSSL::PKCS7.sign(certificate, rsa_key, text, [], OpenSSL::PKCS7::DETACHED)
      #OpenSSL::PKCS7.sign(certificate, rsa_key, text, [], OpenSSL::PKCS7::BINARY)
    end

    def verify(text)
      result = read(text).verify(nil, @certificate_store, nil, nil)
      #read(text).verify(nil, @certificate_store, nil, OpenSSL::PKCS7::NOVERIFY)
      result ? read(text).data : raise(VerificationError.new('Wrong args'))
    rescue => e
      raise VerificationError.new(e.message)
    end

    protected
      def write(pcks7)
        OpenSSL::PKCS7::write_smime pcks7
      end

      def read(text)
        OpenSSL::PKCS7.read_smime(text) rescue OpenSSL::PKCS7.new(text)
      end

    private
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
