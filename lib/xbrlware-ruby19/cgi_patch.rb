# This patch is to fix a bug in Ruby 1.8.x CGI::unescapeHTML
# Till we upgrade to Ruby 1.9, we will use this patch. Ruby 1.9 handles it properly.
# Other alternative is using htmlentities - http://htmlentities.rubyforge.org/
#
# Bug explanation,
# CGI::unescapeHTML("Equity in Earnings&#160;of") returns "Equity in Earnings\240of" instead of "Equity in Earnings of"
# CGI::unescapeHTML is not handling HTML numbers bigger than &#126;
#
# Fix explanation
# If HTML number is bigger than &#126; treat them as &#32; (32 is for space)

# below method copied from ruby-1.8.7-p248, ruby 1.8.7 (2009-12-24 patchlevel 248) for patching.


class CGI
  # Unescape a string that has been HTML-escaped
  #   CGI::unescapeHTML("Usage: foo &quot;bar&quot; &lt;baz&gt;")
  #      # => "Usage: foo \"bar\" <baz>"
  def CGI::unescapeHTML(string)
    string.gsub(/&(amp|quot|gt|lt|\#[0-9]+|\#x[0-9A-Fa-f]+);/n) do
      match = $1.dup
      case match
        when 'amp' then
          '&'
        when 'quot' then
          '"'
        when 'gt' then
          '>'
        when 'lt' then
          '<'
        when /\A#0*(\d+)\z/n then
          if Integer($1) < 256
            32.chr if Integer($1) > 126 
            Integer($1).chr if Integer($1) <= 126
          else
            if Integer($1) < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
              [Integer($1)].pack("U")
            else
              "&##{$1};"
            end
          end
        when /\A#x([0-9a-f]+)\z/ni then
          if $1.hex < 128
            $1.hex.chr
          else
            if $1.hex < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
              [$1.hex].pack("U")
            else
              "&#x#{$1};"
            end
          end
        else
          "&#{match};"
      end
    end
  end

end