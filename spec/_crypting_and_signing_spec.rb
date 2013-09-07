require 'spec_helper'

describe 'Crypting and Signature' do
  describe 'Correct' do
    before do
      add_config(false, false)
      @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config
      @mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
    end

    it 'must generate signed and crypted text' do
      decrypted = @mail.proceed(configuration: Notifier.x509_configuration)
      decrypted.to_s.should eql @raw_mail.body.decoded
    end

    it 'must have valid state' do
      @mail.get_states.detect {|k| k.last == false}.should be_nil
    end
  end

  describe 'Incorrect' do
    it 'sign incorrect passphrase' do
      add_config(true, true)

      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      mail.body.to_s.should_not be_empty

      set_config_param(passphrase: 'wrong')
      -> { mail.proceed(configuration: Notifier.x509_configuration) }.should raise_error OpenSSL::PKey::RSAError
    end

    it 'incorrect certs' do
      add_config(true, true)
      set_config_param(cert: 'cert.crt',
                       key: 'cert.key')
      -> { Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>') }.should raise_error OpenSSL::PKey::RSAError
    end
  end
end