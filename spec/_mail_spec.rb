require 'spec_helper'

describe 'Mail' do
  describe 'proceed' do
    describe 'default' do
      it 'simple mail' do
        mail = simple_email
        text = mail.proceed
        (text =~ /some body/).should be_present
      end

      describe 'coded mail' do
        before do
          add_config(false, false)
          @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
          add_config
          @mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
        end

        it 'with valid default' do
          ActionMailerX509.default_configuration = :test
          @mail.proceed.should eql @raw_mail.body.decoded
        end

        it 'with invalid default' do
          add_none_config
          ActionMailerX509.default_configuration = :none
          -> { @mail.proceed }.should raise_error 'Configuration not valid for sign operations'
        end

        it 'without default' do
          ActionMailerX509.default_configuration = nil
          -> { @mail.proceed }.should raise_error 'Configuration is nil'
        end
      end

      describe 'alternated mail' do
        it 'mail with html block' do
          @mail = alt_email
          (@mail.proceed.to_s =~ /<.+>[^<]*<\/.+>/).should be_present
        end

        it 'mail without html block return text block' do
          @mail = simple_email
          (@mail.proceed.to_s =~ /<.+>[^<]*<\/.+>/).should be_nil
        end
      end
    end
  end
end