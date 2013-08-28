require 'action_mailer_x509'

module Mail #:nodoc:
  class Message #:nodoc:
    def proceed(result_type = 'html', configuration = nil)
      config = ActionMailerX509.get_configuration(configuration)

      if (signed = is_signed?) || is_crypted?
        raise Exception.new('Configuration is nil') unless config
        result = if signed
                   config.get_signer.verify(patched_encoded)
                 else
                   config.get_crypter.decode(body.to_s)
                 end
        if result && (mail = Mail.new(result)).valid?
          mail.proceed(configuration)
        end || result
      end || proceed_part(self, result_type)
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
      # Returns true if the message is a multipart/alternative
      def multipart_alternative?(part)
        part.multipart? && part.sub_type.downcase == 'alternative'
      end

    #need testing
      def proceed_part(part, result_type = 'html')
        if part.multipart?
          if multipart_alternative?(part)
            variants = part.parts.each_with_object({}) {|p, res| res.update(p.sub_type => p)}
            @new_part = variants[result_type] || variants['html'] || variants['plain'] || part.first
          end

          _decode_body(result_type, @new_part || part)
        else
          part.decoded.to_s unless part.attachment?
        end
      end

    # we need manually split body on parts and decode each part separate
      def _decode_body(result_type, obj = self)
        obj.body.split(obj.boundary) if obj.parts.blank? && obj.boundary.present?

        if obj.parts.present?
          obj.parts.map {|part| proceed_part(part, result_type)}.join(break_line(result_type))
        else
          obj.decoded
        end
      end

      def break_line(content_type)
        content_type == 'html' ? '<br>' : "\r\n"
      end

      def convert(text, encoding)
        text.force_encoding(encoding.dasherize)
      end

      def to_part
        part = Mail::Part.new((text = body.encoded))
        part.header[:content_type] = 'text/html' if text.index(/<\w+>/)
        part.header['Content-Transfer-Encoding'] = '8bit'
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
        (header['Content-Type'].encoded =~ /application\/(x-)?pkcs[0-9]+-mime/).present?
      end

      def is_signed?
        (header['Content-Type'].encoded =~ /application\/(x-)?pkcs[0-9]+-signature/).present?
      end
  end
end