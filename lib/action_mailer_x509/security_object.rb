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
    #digest               object    - digest algo - OpenSSL::Digest object (ex OpenSSL::Digest::SHA1.new)
    #pack_key_with_pass   bool      - force repack rsa key with given password
    #subject              Hash      - fields represented by ATTRS const
    #time_from            Time      - certificate start time
    #time_length          int       - certificate life time in seconds
    #crl_points           string or array     - URI:http://my.com/my.crl,URI:http://oth.com/my.crl

    #--------only p12-----------
    #description          string    - p12 description
    #file                 string    - new p12 file path - where have be save new certificate
  class << self
    private
      def to_file(data, path)
        File.open(path, 'wb') do |file|
          file.write(data)
        end
      end

      def subject(params)
        params ||= {}
        params.symbolize_keys!
        subject = params.each_with_object('') do |attr, obj|
          obj << "/#{IATTRS[attr.first]}=#{attr[1]}"
        end
        OpenSSL::X509::Name.parse subject
      end

      def crl_points(crl_points)
        if crl_points.is_a? String
          crl_points
        else
          crl_points.each_with_object([]) {|elem, obj| obj << "#{elem[0]}:#{elem[1]}"}.join(',')
        end
      end

      # not tested
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

      def self_signed_certificate(params = {})
        root_key, root_ca = certificate(params)
        root_ca.serial = 1

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = root_ca
        ef.issuer_certificate = root_ca
        root_ca.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
        root_ca.add_extension(ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true))
        root_ca.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
        root_ca.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always', false))
        root_ca.add_extension(ef.create_extension('crlDistributionPoints', crl_points(params[:crl_points]), false)) if params[:crl_points]

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

        root_ca.sign(root_key, params[:digest] || default_digest)
        [ root_key, root_ca ]
      end

      def signed_certificate(params = {})
        root_key, root_ca = self_signed_certificate(params)
        key, cert = certificate(params, root_ca)
        cert.serial = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = root_ca
        cert.add_extension(ef.create_extension('keyUsage', 'digitalSignature', true))
        cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
        cert.add_extension(ef.create_extension('crlDistributionPoints', crl_points(params[:crl_points]), false)) if params[:crl_points]
        cert.sign(root_key,  params[:digest] || default_digest)

        [ key, cert ]
      end

      def default_digest
        OpenSSL::Digest::SHA1.new
      end

      def revoke_check(cert)
        require 'net/http'

        uris = get_crls(cert)
        if uris.present?
          crl = Net::HTTP.get_response(URI(uris[0])) # you may need to follow redirects here, but let's assume you got the CRL.                                                   # Also note that the Apple WWDRCA CRL is like 28MB so you may want to cache this damned thing. OCSP would be nicer but it's a bit trickier to validate.
          @crl = OpenSSL::X509::CRL.new(crl)
          raise(StandardError, 'Invalid CRL for certificate') if not @crl.verify(cert.public_key)
          if @crl.revoked.find { |revoked| revoked.serial == cert.serial.to_i }
            true
          else
            false
          end
        end || false
      end

      def issue_crl(revoke_info, serial, lastup, nextup, extensions,
          issuer, issuer_key, digest)
        crl = OpenSSL::X509::CRL.new
        crl.issuer = issuer.subject
        crl.version = 1
        crl.last_update = lastup
        crl.next_update = nextup
        revoke_info.each{|rserial, time, reason_code|
          revoked = OpenSSL::X509::Revoked.new
          revoked.serial = rserial
          revoked.time = time
          enum = OpenSSL::ASN1::Enumerated(reason_code)
          ext = OpenSSL::X509::Extension.new("CRLReason", enum)
          revoked.add_extension(ext)
          crl.add_revoked(revoked)
        }
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.issuer_certificate = issuer
        ef.crl = crl
        crlnum = OpenSSL::ASN1::Integer(serial)
        crl.add_extension(OpenSSL::X509::Extension.new("crlNumber", crlnum))
        extensions.each{|oid, value, critical|
          crl.add_extension(ef.create_extension(oid, value, critical))
        }
        crl.sign(issuer_key, digest)
        crl
      end
    public

      #def test_revoked
      #
      #  # CRLReason ::= ENUMERATED {
      #  #      unspecified             (0),
      #  #      keyCompromise           (1),
      #  #      cACompromise            (2),
      #  #      affiliationChanged      (3),
      #  #      superseded              (4),
      #  #      cessationOfOperation    (5),
      #  #      certificateHold         (6),
      #  #      removeFromCRL           (8),
      #  #      privilegeWithdrawn      (9),
      #  #      aACompromise           (10) }
      #
      #  now = Time.at(Time.now.to_i)
      #  revoke_info = [
      #      [1, Time.at(0),          1],
      #      [2, Time.at(0x7fffffff), 2],
      #      [3, now,                 3],
      #      [4, now,                 4],
      #      [5, now,                 5],
      #  ]
      #  cert = issue_cert(@ca, @rsa2048, 1, Time.now, Time.now+3600, [],
      #                    nil, nil, OpenSSL::Digest::SHA1.new)
      #  crl = issue_crl(revoke_info, 1, Time.now, Time.now+1600, [],
      #                  cert, @rsa2048, OpenSSL::Digest::SHA1.new)
      #  revoked = crl.revoked
      #  assert_equal(5, revoked.size)
      #  assert_equal(1, revoked[0].serial)
      #  assert_equal(2, revoked[1].serial)
      #  assert_equal(3, revoked[2].serial)
      #  assert_equal(4, revoked[3].serial)
      #  assert_equal(5, revoked[4].serial)
      #
      #  assert_equal(Time.at(0), revoked[0].time)
      #  assert_equal(Time.at(0x7fffffff), revoked[1].time)
      #  assert_equal(now, revoked[2].time)
      #  assert_equal(now, revoked[3].time)
      #  assert_equal(now, revoked[4].time)
      #
      #  assert_equal("CRLReason", revoked[0].extensions[0].oid)
      #  assert_equal("CRLReason", revoked[1].extensions[0].oid)
      #  assert_equal("CRLReason", revoked[2].extensions[0].oid)
      #  assert_equal("CRLReason", revoked[3].extensions[0].oid)
      #  assert_equal("CRLReason", revoked[4].extensions[0].oid)
      #
      #  assert_equal("Key Compromise", revoked[0].extensions[0].value)
      #  assert_equal("CA Compromise", revoked[1].extensions[0].value)
      #  assert_equal("Affiliation Changed", revoked[2].extensions[0].value)
      #  assert_equal("Superseded", revoked[3].extensions[0].value)
      #  assert_equal("Cessation Of Operation", revoked[4].extensions[0].value)
      #
      #  assert_equal(false, revoked[0].extensions[0].critical?)
      #  assert_equal(false, revoked[1].extensions[0].critical?)
      #  assert_equal(false, revoked[2].extensions[0].critical?)
      #  assert_equal(false, revoked[3].extensions[0].critical?)
      #  assert_equal(false, revoked[4].extensions[0].critical?)
      #
      #  crl = OpenSSL::X509::CRL.new(crl.to_der)
      #  assert_equal("Key Compromise", revoked[0].extensions[0].value)
      #  assert_equal("CA Compromise", revoked[1].extensions[0].value)
      #  assert_equal("Affiliation Changed", revoked[2].extensions[0].value)
      #  assert_equal("Superseded", revoked[3].extensions[0].value)
      #  assert_equal("Cessation Of Operation", revoked[4].extensions[0].value)
      #
      #  revoke_info = (1..1000).collect{|i| [i, now, 0] }
      #  crl = issue_crl(revoke_info, 1, Time.now, Time.now+1600, [],
      #                  cert, @rsa2048, OpenSSL::Digest::SHA1.new)
      #  revoked = crl.revoked
      #  assert_equal(1000, revoked.size)
      #  assert_equal(1, revoked[0].serial)
      #  assert_equal(1000, revoked[999].serial)
      #end


      def crl(cert, key)
        now = params[:time_from] || Time.now
        crl = issue_crl([], 1, now, now + (params[:time_length] || 1.year), [],
                        cert, key, params[:digest] || default_digest)
        crl.to_der
      end

      def p7_self_signed_certificate(params = {})
        params.symbolize_keys!

        key, cert = self_signed_certificate(params)
        {key: key, certificate: cert}
      end

      def p7_signed_certificate(params = {})
        params.symbolize_keys!
        key, cert = signed_certificate(params)
        {key: key, certificate: cert}
      end

      def p12_certificate(params = {})
        params.symbolize_keys!

        key, cert = signed_certificate(params)
        p12 = OpenSSL::PKCS12.create(params[:password], params[:description] || 'My Name', key, cert)
        bytes = p12.to_der
        to_file(bytes, path) if params[:file]
        bytes
      end

      def get_extensions(cert)
        cert.extensions.each_with_object({}) do |ext, obj|
          e = OpenSSL::X509::Extension.new(ext)
          obj.update(e.oid => e.value)
        end
      end

      def get_crls(cert)
        points = get_extensions(cert)['crlDistributionPoints']
        points.split(/\nFull Name:\n  URI:/).from(1)
      end


      def validate_certificate(cert_file)
        criteria = {}

        begin
          cert = OpenSSL::X509::Certificate.new(File::read(cert_file))
          criteria.update(expired: true) if
              cert.not_before > Time.now ||
              cert.not_after < Time.now

          criteria.update(revoked: true) if revoke_check(cert)
        rescue
          criteria.update(invalid_signature: true)
        end
        criteria
      end


#    def validate_certificate2(cert_file)
#      cert = R509::Cert.load_from_file("my_website.pem")
## get the first OCSP AIA URI. There can be more than one
## (degenerate example!)
#      ocsp_uri = cert.aia.ocsp.uris[0]
#      issuer = R509::Cert.load_from_file("my_issuer.pem")
#      cert_id = OpenSSL::OCSP::CertificateId.new(cert.cert,issuer.cert)
#      request = OpenSSL::OCSP::Request.new
#      request.add_certid(cert_id)
## we're going to make a GET request per RFC 5019. You can also POST the
## binary DER encoded version if you're more of an RFC 2560 partisan
#      request_uri = URI(ocsp_uri+"/"+URI.encode_www_form_component(req_pem.strip))
#      http_response = Net::HTTP.get_response(request_uri)
#      if http_response.code != "200"
#        raise StandardError, "Invalid response code from OCSP responder"
#      end
#      response = OpenSSL::OCSP::Response.new(http_response.body)
#      if response.status != 0
#        raise StandardError, "Not a successful status"
#      end
#      if response.basic[0][0].serial != cert.serial
#        raise StandardError, "Not the same serial"
#      end
#      if response.basic[0][1] != 0 # 0 is good, 1 is revoked, 2 is unknown.
#        raise StandardError, "Not a good status"
#      end
#      current_time = Time.now
#      if response.basic[0][4] > current_time or response.basic[0][5] < current_time
#        raise StandardError, "The response is not within its validity window"
#      end
## we also need to verify that the OCSP response is signed by
## a certificate that is allowed and chains up to a trusted root.
## To do this you'll need to build an OpenSSL::X509::Store object
## that contains the certificate you're checking + intermediates + root.
#      store = OpenSSL::X509::Store.new
#      store.add_cert(cert.cert)
#      store.add_cert(issuer.cert) #assuming issuer is a trusted root here, but in reality you'll need at least one more certificate
#      if response.basic.verify([],store) != true
#        raise StandardError, "Certificate verification error"
#      end
#    end
  end
end
