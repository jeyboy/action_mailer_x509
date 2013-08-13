require 'spec_helper'

describe 'Test basic functions' do
  describe 'Correct' do
    it 'Signature' do
      add_config(false, false)
      raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config(true, false)
      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      verified = mail.proceed(Notifier.x509_configuration)
      verified.should eql raw_mail.body.to_s
    end

    it 'Crypting' do
      add_config(false, false)
      raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config(false, true)
      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      decrypted = mail.proceed(Notifier.x509_configuration)
      decrypted.to_s.should eql raw_mail.body.decoded
    end

    it 'Crypting and Signature' do
      add_config(false, false)
      raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config
      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      decrypted = mail.proceed(Notifier.x509_configuration)
      decrypted.to_s.should eql raw_mail.body.decoded
    end
  end

  describe 'Incorrect' do

  end
end