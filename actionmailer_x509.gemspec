Gem::Specification.new do |s|
  s.name = 'action_mailer_x509'
  s.version = '0.5.3.2'
  s.authors = ['Jenua Boiko']
  s.email = 'jeyboy1985@gmail.com'
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage = 'http://github.com/jeyboy/action_mailer_x509'
  s.require_path = 'lib'
  s.rubygems_version = '1.3.5'
  s.summary = "This Rails gem allows you to send X509 signed and\\or crypted mails."
  s.license = 'BSD'

  s.add_dependency 'rake'
  s.add_dependency 'actionmailer'
  s.add_dependency 'mail'
  #s.add_development_dependency 'rspec'
end

