class SecurityObject
  ATTRS = {     'C' => :country,
                'ST' => :state,
                'L' => :location,
                'O' => :organization,
                'OU' => :organizational_unit,
                'CN' => :common_name,
                'emailAddress' => :email}

  IATTRS = ATTRS.invert

  #params:  Hash
    #key_length           int       - length of the rsa key
    #password             string    - passphrase for key/certificate
    #pack_key_with_pass   bool      - force repack rsa key with given password
    #subject              Hash      - fields represented by ATTRS const
    #time_from            Time      - certificate start time
    #time_length          int       - certificate life time in seconds
    #description          string    - p12 description
    #file                 string    - file path - where have be save new certificate
  class << self
    private
      def to_file(data, path)
        File.open(path, 'wb') do |file|
          file.write(data)
        end
      end

      def subject(params)
        subject = (params || {}).each_with_object('') do |attr, obj|
          obj << "/#{IATTRS[attr.first]}=#{attr[1]}"
        end
        OpenSSL::X509::Name.parse subject
      end

      def repack_key(rsa_key, password)
        cipher =  OpenSSL::Cipher::Cipher.new('des3')
        private_key = rsa_key.to_pem(cipher, password)
        public_key = rsa_key.public_key.to_pem
        OpenSSL::PKey::RSA.new(private_key + public_key, password)
      end

      def rsa_key(params={})
        key = OpenSSL::PKey::RSA.new(params[:key_length] || 4096) # the CA's public/private key
        (repack_key(key, params[:password]) if params[:pack_key_with_pass]) || key
      end

      def certificate(params = {}, root_certificate = nil)
        root_key = rsa_key(params)

        root_ca = OpenSSL::X509::Certificate.new
        root_ca.version = 2 # cf. RFC 5280 - to make it a "v3" certificate
        root_ca.serial = 1
        root_ca.subject = subject(params[:subject])
        root_ca.issuer = (root_certificate || root_ca).subject # root CA's are "self-signed"
        root_ca.public_key = root_key.public_key
        root_ca.not_before = params[:time_from] || Time.now
        root_ca.not_after = root_ca.not_before + (params[:time_length] || 1.year)  #2 * 365 * 24 * 60 * 60 # 2 years validity

        [ root_key, root_ca ]
      end
    public

    def self_signed_certificate(params = {})
      params.symbolize_keys!

      root_key, root_ca = certificate(params)
      root_ca.serial = 1

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = root_ca
      ef.issuer_certificate = root_ca
      root_ca.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
      root_ca.add_extension(ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true))
      root_ca.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
      root_ca.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always', false))
      root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)


      [ root_key, root_ca ]


#      key = OpenSSL::PKey::RSA.new(1024)
#      public_key = key.public_key
#
#      subject = "/C=BE/O=Test/OU=Test/CN=Test"
#
#      cert = OpenSSL::X509::Certificate.new
#      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
#      cert.not_before = Time.now
#      cert.not_after = Time.now + 365 * 24 * 60 * 60
#      cert.public_key = public_key
#      cert.serial = 0x0
#      cert.version = 2
#
#      ef = OpenSSL::X509::ExtensionFactory.new
#      ef.subject_certificate = cert
#      ef.issuer_certificate = cert
#      cert.extensions = [
#          ef.create_extension("basicConstraints","CA:TRUE", true),
#          ef.create_extension("subjectKeyIdentifier", "hash"),
## ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
#      ]
#      cert.add_extension ef.create_extension("authorityKeyIdentifier",
#                                             "keyid:always,issuer:always")
#
#      cert.sign key, OpenSSL::Digest::SHA1.new
    end

    def signed_certificate(params = {})
      params.symbolize_keys!
      root_key, root_ca = self_signed_certificate(params)
      key, cert = certificate(params, root_ca)
      cert.serial = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = root_ca
      cert.add_extension(ef.create_extension('keyUsage', 'digitalSignature', true))
      cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
      cert.sign(root_key, OpenSSL::Digest::SHA256.new)

      [ key, cert ]
    end


    def p12_certificate(params = {})
      params.symbolize_keys!

      key, cert = signed_certificate(params)

      #root_key = OpenSSL::PKey::RSA.new 4096 # the CA's public/private key
      #root_ca = OpenSSL::X509::Certificate.new
      #root_ca.version = 2 # cf. RFC 5280 - to make it a "v3" certificate
      #root_ca.serial = 1
      #root_ca.subject = OpenSSL::X509::Name.parse "/DC=org/DC=ruby-lang/CN=Ruby CA"
      #root_ca.issuer = root_ca.subject # root CA's are "self-signed"
      #root_ca.public_key = root_key.public_key
      #root_ca.not_before = Time.now
      #root_ca.not_after = root_ca.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
      #
      #ef = OpenSSL::X509::ExtensionFactory.new
      #ef.subject_certificate = root_ca
      #ef.issuer_certificate = root_ca
      #root_ca.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
      #root_ca.add_extension(ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true))
      #root_ca.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
      #root_ca.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always', false))
      #root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)
      #
      ## The next step is to create the end-entity certificate using the root CA
      ## certificate.
      ##
      #key = OpenSSL::PKey::RSA.new 4096
      #cert = OpenSSL::X509::Certificate.new
      #cert.version = 2
      #cert.serial = 2
      #cert.subject = OpenSSL::X509::Name.parse "/DC=org/DC=ruby-lang/CN=Ruby certificate"
      #cert.issuer = root_ca.subject # root CA is the issuer
      #cert.public_key = key.public_key
      #cert.not_before = Time.now
      #cert.not_after = cert.not_before + 1 * 365 * 24 * 60 * 60 # 1 years validity
      #
      #ef = OpenSSL::X509::ExtensionFactory.new
      #ef.subject_certificate = cert
      #ef.issuer_certificate = root_ca
      #cert.add_extension(ef.create_extension('keyUsage', 'digitalSignature', true))
      #cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
      #cert.sign(root_key, OpenSSL::Digest::SHA256.new)

      p12 = OpenSSL::PKCS12.create(params[:password], params[:description] || 'My Name', key, cert)
      bytes = p12.to_der
      to_file(bytes, path) if params[:file]
      bytes
    end
  end
end