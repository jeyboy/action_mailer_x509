require 'action_mailer_x509'

module Mail #:nodoc:
  class Message #:nodoc:
    def proceed(configuration = nil)
      config = ActionMailerX509.get_configuration(configuration)

      if is_signed?
        raise Exception.new('Configuration is nil') unless config
        # call patched_encoded
        result = config.get_signer.verify(patched_encoded)
        if result && (mail = Mail.new(result)).valid?
          mail.proceed(configuration)
        end || result
      elsif is_crypted?
        raise Exception.new('Configuration is nil') unless config
        result = config.get_crypter.decode(body.to_s)
        if result && (mail = Mail.new(result)).valid?
          mail.proceed(configuration)
        end || result
      end || body.decoded
    end

    #def method_missing(name, *args, &block)
    #  if name =~ /_as_utf8\z/
    #    self.send(name.to(name.length - 8), args).force_encoding('UTF-8') rescue ''
    #  end
    #end

    def content
      parts.empty? ? to_part : body.encoded
    end

    protected
      def to_part
        part = Mail::Part.new((text = body.encoded).force_encoding('koi8-r'))
        part.header[:content_type] = 'text/html' if text.index(/<\w+>/)
        part.encoded #patched_encoded.force_encoding('koi8-r')
      end

      def valid?
        header['Content-Type'].present? && body.encoded.length > 0
      end

      #PATCH: body.encoded return wrong result in encoded func
      def patched_encoded
        buffer = header.encoded
        buffer << "\r\n"
        buffer << body.to_s
        buffer
      end

      def is_crypted?
        (header['Content-Type'].encoded =~ /application\/x-pkcs[0-9]+-mime/).present?
      end

      def is_signed?
        check_parts || check_body
      end

      def check_parts
        (parts.first.body.to_s == 'This is an S/MIME signed message') rescue false
      end

      def check_body
        (body.to_s =~ /This is an S\/MIME signed message/).present?
      end
  end
end