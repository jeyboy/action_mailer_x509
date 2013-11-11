class ConfigurationPart
  def proceed_settings(params)
    params.symbolize_keys!
    params.each_pair { |k, v| self.send("#{k}=".to_sym, v) }
  end

  def initialize(params = {})
    proceed_settings(params)
  end

  class_attribute :certificate
  class_attribute :key
  class_attribute :passphrase
  class_attribute :path

  def certificate
    path.join(@certificate)
  end

  def key
    path.join(@key)
  end

  def get_processor
    ActionMailerX509::X509.new(obj_configuration)
  end

  def get_certificate_info
    worker = get_processor

    subject_attrs = worker.certificate.subject.to_a
    subject_attrs = subject_attrs.each_with_object({}) do |attr, obj|
      obj.update(SecurityObject::ATTRS[attr.first] => attr[1])
    end

    {
        from: worker.certificate.not_before,
        to: worker.certificate.not_after,
    }.reverse_merge!(subject_attrs)
  end

  def valid?
    throw Exception.new('Overriding require')
  end

  def obj_configuration
    conf = { pass_phrase: passphrase }

    if @key
      conf.merge(certificate: certificate, rsa_key: key)
    else
      conf.merge(certificate: certificate)
    end
  end
end