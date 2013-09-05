require 'action_mailer_x509'

module Mail #:nodoc:
  class Message #:nodoc:

    #fix mail gem bug on decoding
    def subject( val = nil )
      val ||= header[:subject].default
      val.gsub!(' ', '_') if val && val.start_with?('=?')
      default( :subject, val )
      header[:subject].default
    end

    def proceed(result_type = 'html', configuration = nil)
      proceed_part(_proceed(configuration), result_type)
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

    def get_states
      {
          crypted: (body.to_s =~ /application\/(x-)?pkcs[0-9]+-mime/).present?,
          signed: (body.to_s =~ /application\/(x-)?pkcs[0-9]+-signature/).present?
      }
    end

    protected
      # Returns true if the message is a multipart/alternative
      def alternative?(part)
        part.sub_type.downcase == 'alternative'
      end


      def _proceed(configuration = nil)
        config = ActionMailerX509.get_configuration(configuration)
        if (signed = is_signed?) || is_crypted?
          raise Exception.new('Configuration is nil') unless config
          result = if signed
                     config.get_signer.verify(patched_encoded)
                   else
                     config.get_crypter.decode(body.to_s)
                   end
          if result && (mail = Mail.new(result)).valid?
            mail._proceed(configuration)
          end || result
        end || self
      end

      def proceed_part(part, result_type = 'html')
        if part.multipart?
          if alternative?(part)
            variants = part.parts.each_with_object({}) {|p, res| res.update(p.sub_type => p)}
            @new_part = variants[result_type] || variants['html'] || variants['plain'] || part.first
          end

          _decode_body(result_type, @new_part || part)
        else
          part.decoded unless part.attachment?
        end.to_s
      end

    # we need manually split body on parts and decode each part separate
      def _decode_body(result_type, obj = self)
        obj.body.split!(obj.boundary) if obj.parts.blank? && obj.boundary.present?


        if obj.parts.present?
          proceed_parts = obj.parts.map {|part| proceed_part(part, result_type).force_encoding('utf-8')}
          proceed_parts.join(break_line(result_type))
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
      rescue
        false
      end

      def is_signed?
        (header['Content-Type'].encoded =~ /application\/(x-)?pkcs[0-9]+-signature/).present?
      rescue
        false
      end
  end
end