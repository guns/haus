# -*- encoding: utf-8 -*-

class Haus
  module LSColors
    # Default values, used as a mask
    LSCOLORS  = 'exfxcxdxbxegedabagacad'
    LS_COLORS = 'di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:ex=01;32'

    class << self
      # Look up color information; returns empty string when not found.
      def [] type
        @colors[type] || ''
      end

      # Returns key suitable for use with Haus::LSColors#[]
      def ftype file
        stat = File.lstat file

        case stat.ftype
        when 'directory'
          if not (stat.mode & 0002).zero?
            stat.sticky? ? 'stickyOtherWritable' : 'otherWritable'
          else
            'directory'
          end
        when 'file'
          if stat.executable?
            if stat.setuid?
              'setuid'
            elsif stat.setgid?
              'setgid'
            else
              'executable'
            end
          else
            'file'
          end
        else
          # File::Stat#ftype returns valid keys otherwise
          stat.ftype
        end
      end

      # Redefine internal color table with given string or from environment
      def parse str = nil, type = nil
        type ||= if str                       then str =~ /=/ ? :gnu : :bsd
        elsif system 'ls --color &>/dev/null' then :gnu
        else                                       :bsd
        end

        case type
        when :gnu
          pos  = gnu str || ENV['LS_COLORS'] || ''
          mask = gnu LS_COLORS
        when :bsd
          pos  = bsd str || ENV['LSCOLORS'] || ''
          mask = bsd LSCOLORS
        else
          raise 'Undefined ls color type %s' % type.inspect
        end

        # Camel case keys to match File#ftype
        @colors = {
          'directory'           => pos[ 0] || mask[ 0],
          'link'                => pos[ 1] || mask[ 1],
          'socket'              => pos[ 2] || mask[ 2],
          'fifo'                => pos[ 3] || mask[ 3],
          'executable'          => pos[ 4] || mask[ 4],
          'blockSpecial'        => pos[ 5] || mask[ 5],
          'characterSpecial'    => pos[ 6] || mask[ 6],
          'setuid'              => pos[ 7] || mask[ 7],
          'setgid'              => pos[ 8] || mask[ 8],
          'stickyOtherWritable' => pos[ 9] || mask[ 9],
          'otherWritable'       => pos[10] || mask[10]
        }
      end

      private

      # LS_COLORS is a colon-delimited string of SGR values.
      def gnu str
        # We Array#inject because Hash[] is lacking in 1.8.6
        str.split(':').inject Hash.new do |h, e|
          h.store *(e.split '='); h
        end.values_at *%w[di ln so pi ex bd cd su sg tw ow]
      rescue
        []
      end

      # LSCOLORS uses [A-Ha-hx] to represent the basic 8-color palette.
      # The following translates ASCII values into SGR codes.
      def bsd str
        str = str.dup.force_encoding 'US-ASCII' if str.respond_to? :force_encoding
        str.scan(/../).map do |colors|
          # Enumerator#with_index unavailable in 1.8.6
          acc = []
          colors.unpack('C*').each_with_index do |n, i|
            acc << case n
            when 65..72  then (n - 35 + (i*10)).to_s + ';1'
            when 97..104 then (n - 67 + (i*10)).to_s
            else              (39     + (i*10)).to_s
            end
          end
          acc.join ';'
        end
      rescue
        []
      end
    end

    # Seed color table now
    parse
  end
end
