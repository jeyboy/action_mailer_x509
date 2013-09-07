require 'spec_helper'

describe 'Signature' do
  describe 'Correct' do
    before do
      add_config(false, false)
      @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')

      add_config(true, false)
      @mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
    end

    it 'Must generate signature' do
      @mail.body.to_s.should_not eql @raw_mail.body.to_s
    end

    it 'Verification check' do
      verified = @mail.proceed(configuration: Notifier.x509_configuration)
      verified.should eql @raw_mail.body.to_s
    end

    it 'must have valid state' do
      states = @mail.get_states
      states[:signed].should eql true
    end
  end

  describe 'Incorrect' do
    it 'incorrect text' do
      add_config(true, false)
      mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      mail.body = mail.body.to_s.gsub(/[0-9]/, 'g')
      -> { mail.proceed(configuration: Notifier.x509_configuration) }.should raise_error VerificationError
    end
  end
end