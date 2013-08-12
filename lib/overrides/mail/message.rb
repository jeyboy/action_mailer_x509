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

    def method_missing(name, *args, &block)
      elems = name.to_s.split('_as_')

      if elems.size == 2
        result = self.send(elems.first.to_sym, *args)
        if result.is_a? String
          convert(result, elems.last)
        elsif result.respond_to? :to_a
          result.to_a.map {|item| convert(item.to_s, elems.last)}
        else
          convert(result.to_s, elems.last)
        end
      end
    end

    def content
      parts.empty? ? to_part : body.encoded
    end

    protected
      def convert(text, encoding)
        text.force_encoding(encoding.dasherize)
      end

      def to_part
        part = Mail::Part.new((text = body.encoded).force_encoding('koi8-r'))
        part.header[:content_type] = 'text/html' if text.index(/<\w+>/)
        #part.header['Content-Transfer-Encoding'] = 'base64'
        part.encoded
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