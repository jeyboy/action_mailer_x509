require 'spec_helper'

describe 'Test additional functions' do
  describe 'Correct' do
    describe 'Certificate generation' do
      it 'Must generate p12' do
        p12_bytes = SecurityObject.p12_certificate({:password => 'demo'})
        lambda { OpenSSL::PKCS12.new p12_bytes, 'demo' }.should_not raise_error
      end

      it 'Must generate p12 with params' do
        subject_settings = {
            :country => 'TestCountry',
            :state => 'TestState',
            :location => 'TestLocation',
            :organization => 'TestOrganization',
            :organizational_unit => 'TestOrganizationalUnit',
            :common_name => 'TestCommonName',
            :email => 'a@b.com'
        }
        p12_bytes = SecurityObject.p12_certificate(
            :password => 'demo',
            :subject => subject_settings
        )
        p12 = OpenSSL::PKCS12.new p12_bytes, 'demo'

        subject_attrs = p12.certificate.subject.to_a
        subject_attrs.each do |attr|
          subject_settings[SecurityObject::ATTRS[attr.first]].should eql attr[1]
        end
      end

      it 'Must generate p7 key with password' do
        objs = SecurityObject.p7_self_signed_certificate(
            :password => 'try_pass',
            :pack_key_with_pass => true
        )
        key_bytes = objs[:key].to_pem
        -> { OpenSSL::PKey::RSA.new(key_bytes, 'try_pass') }.should_not raise_error
      end

      #it 'Must generate p7 key with password' do
      #  objs = SecurityObject.p7_self_signed_certificate(
      #      :password => 'try_pass',
      #      :pack_key_with_pass => true
      #  )
      #  key_bytes = objs[:key].to_pem
      #  -> { OpenSSL::PKey::RSA.new(key_bytes, nil) }.should raise_error
      #end

      it 'Must generate p7 cert with crl' do
        crl = [
          ['URI', 'http://my.com/my.crl'],
          ['URI', 'http://oth.com/my.crl']
        ]
        objs = SecurityObject.p7_self_signed_certificate(
            :crl_points => crl
        )
        cert = objs[:certificate]
        extensions = SecurityObject.get_extensions(cert)
        extensions['crlDistributionPoints'].should_not be_nil
      end
    end
  end

  describe 'Incorrect' do
    it 'Must dont open p12 with wrong pass' do
      p12_bytes = SecurityObject.p12_certificate({:password => 'demo'})
      lambda { OpenSSL::PKCS12.new p12_bytes, 'wrong' }.should raise_error
    end
  end
end