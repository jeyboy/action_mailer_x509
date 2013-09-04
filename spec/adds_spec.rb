require 'spec_helper'

describe 'Test additional functions' do
  describe 'Correct' do
    describe 'Certificate generation' do
      it 'Must generate p12' do
        p12_bytes = SecurityObject.p12_certificate({:password => 'demo'})
        lambda { OpenSSL::PKCS12.new p12_bytes, 'demo' }.should_not raise_error
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