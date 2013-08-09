ActionMailerX509.settings do |config|

  #Set collection of configurations for future use
  #config.add_configuration :demo,
  #                         {
  #                             sign_enable: false,
  #                             crypt_enable: true,
  #                             sign_cert: 'cert.crt',
  #                             sign_key: 'cert.key',
  #                             sign_passphrase: 'demo',
  #                             crypt_cert: 'cert.crt',
  #                             crypt_key: 'cert.key',
  #                             crypt_passphrase: 'demo',
  #                             certs_path: Rails.root.join('certs')
  #                         }
  #
  #config.add_configuration :hisp,
  #                         {
  #                             sign_enable: true,
  #                             crypt_enable: true,
  #                             sign_cert: 'ca.crt',
  #                             sign_key: 'ca.key',
  #                             sign_passphrase: 'hisp',
  #                             crypt_cert: 'ca.crt',
  #                             crypt_key: 'ca.key',
  #                             crypt_passphrase: 'hisp',
  #                             certs_path: Rails.root.join('certs')
  #                         }
  #

  # You may set configuration which will be use by default
  #config.default_configuration = :hisp
end