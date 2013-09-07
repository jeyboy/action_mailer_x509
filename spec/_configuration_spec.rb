require 'spec_helper'

describe 'Configuration' do
  describe 'Correct' do
    it 'non x509' do
      add_config(false, false)
      get_config.should be_valid
    end

    it 'p7 init' do
      add_config(true, true)
      get_config.should be_valid
    end

    it 'p12 init' do
      add_config(true, true, true)
      get_config.should be_valid
    end
  end

  describe 'Incorrect' do
    it 'must return false on wrong passphrase' do
      add_config
      set_config_param(sign_passphrase: 'wrong')
      get_config.should_not be_valid
    end

    it 'must return false on wrong certificate' do
      add_usual_cert_as_p12_config
      get_config.should_not be_valid
    end
  end
end