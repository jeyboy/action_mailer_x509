ActionMailerX509.settings do |config|

  #Set collection of configurations for future use
  #config.add_configuration :demo,
  #                         {
  #                             sign_enable: false,
  #                             crypt_enable: true,
  #                             sign_cert: 'cert.crt',
  #                             sign_key: 'cert.key',
  #                             sign_passphrase: 'demo',
  #                             crypt_cert: 'other_cert.crt',
  #                             crypt_key: 'other_cert.key',
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
  #                             crypt_cert: 'capa.crt',
  #                             crypt_key: 'capa.key',
  #                             crypt_passphrase: 'hisp',
  #                             certs_path: Rails.root.join('certs')
  #                         }
  #
  #config.add_configuration :common,
  #                         {
  #                             sign_enable: true,
  #                             crypt_enable: true,
  #                             cert: 'ca.crt',
  #                             key: 'ca.key',
  #                             passphrase: 'hisp'
  #                             crypt_passphrase: 'hisp',
  #                             certs_path: Rails.root.join('certs')
  #                         }
  #

  # You may set configuration which will be use by default
  #config.default_configuration = :hisp

  #Also you may set default certs path and not set certs_path in configs
  #config.default_certs_path = Rails.root.join('certs')
end