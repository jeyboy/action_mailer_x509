require 'spec_helper'

describe 'Crypting' do
  describe 'Correct' do
    before do
      add_config(false, false)
      @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config(false, true)
      @mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
    end

    it 'Must generate crypted text' do
      @mail.body.decoded.should_not eql @raw_mail.body.decoded
    end

    it 'Must generate crypted text' do
      decrypted = @mail.proceed(configuration: Notifier.x509_configuration)
      decrypted.to_s.should eql @raw_mail.body.decoded
    end

    it 'must have valid state' do
      states = @mail.get_states
      states[:crypted].should eql true
    end
  end

  describe 'Incorrect' do
    it 'incorrect text' do
      add_config(false, true)
      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      mail.body = mail.body.to_s.gsub(/[0-9]/, 'g')
      -> { mail.proceed(configuration: Notifier.x509_configuration) }.should raise_error DecodeError
    end
  end
end