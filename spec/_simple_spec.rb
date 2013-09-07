require 'spec_helper'

describe 'Simple' do
  describe 'Correct' do
    it 'must return usual mail' do
      add_config(false, false)
      @raw_mail = Notifier.fufu('<destination@foobar.com>', '<demo@foobar.com>')
      @raw_mail.get_states.detect {|k| k.last == true}.should be_nil
    end
  end

  describe 'Incorrect' do

  end
end