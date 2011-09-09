# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'haus/ls_colors'
require 'haus/test/helper/minitest'
require 'haus/test/helper/test_user'

$user ||= Haus::TestUser[$$]

class Haus::LSColorsSpec < MiniTest::Spec
  it 'must contain default LSCOLORS and LS_COLORS values' do
    Haus::LSColors.constants.map { |c| c.to_s }.sort.must_equal %w[LSCOLORS LS_COLORS].sort
  end

  describe :self do
    it 'must have created the color table on class definition' do
      colors = Haus::LSColors.instance_variable_get :@colors
      colors.must_be_kind_of Hash
      colors.keys.all? { |k| k.is_a? Symbol }.must_equal true
    end

    describe :[] do
      it 'must always return a string' do
        Haus::LSColors[:dangerous].must_equal ''
        Haus::LSColors['/etc/passwd'].must_be_kind_of String
      end

      it 'must only accept Symbol and String values' do
        lambda { Haus::LSColors[0] }.must_raise ArgumentError
      end

      it 'must return the style value for a file if passed a String' do
        Haus::LSColors.parse 'aabb'
        Haus::LSColors[$user.hausfile.first].must_equal ''
        Haus::LSColors[$user.hausfile(:dir).first].must_equal '30;40'
        Haus::LSColors[$user.hausfile(:link).first].must_equal '31;41'
      end

      it 'must return the style value for the given Symbol key' do
        Haus::LSColors.parse 'AaBb'
        Haus::LSColors[:file].must_equal ''
        Haus::LSColors[:directory].must_equal '30;1;40'
        Haus::LSColors[:link].must_equal '31;1;41'
      end
    end

    describe :ftype do
      it 'must correctly detect directory types' do
        dir = $user.hausfile(:dir).first
        Haus::LSColors.ftype(dir).must_equal :directory
        File.chmod 0777, dir
        Haus::LSColors.ftype(dir).must_equal :otherWritable
        File.chmod 01777, dir
        Haus::LSColors.ftype(dir).must_equal :stickyOtherWritable
      end

      it 'must correctly detect executable types' do
        file = $user.hausfile(:file).first
        Haus::LSColors.ftype(file).must_equal :file
        File.chmod 0755, file
        Haus::LSColors.ftype(file).must_equal :executable
        File.chmod 04755, file
        Haus::LSColors.ftype(file).must_equal :setuid
        File.chmod 02755, file
        Haus::LSColors.ftype(file).must_equal :setgid
      end

      it 'must otherwise return the file type' do
        Haus::LSColors.ftype($user.hausfile(:link).first).must_equal :link
        Haus::LSColors.ftype('/dev/null').must_equal :characterSpecial
        Haus::LSColors.ftype(%x(mount).split("\n").find { |l| l =~ %r{\b/\b} }[/\S+/]).must_equal :blockSpecial
        # TODO: FIFOs and sockets
      end
    end

    describe :parse do
      it 'must accept 0..2 arguments' do
        Haus::LSColors.method(:parse).arity.must_equal -1
        assert_raises StandardError do
          Haus::LSColors.parse nil
          Haus::LSColors.parse 'xx', :bsd
          raise StandardError
        end
      end

      it 'must correctly determine color format when not specified' do
        Haus::LSColors.parse 'aaxxxxxxxx'
        Haus::LSColors[:directory].must_equal '30;40'
        Haus::LSColors.parse 'di=31;31:ln=39;49'
        Haus::LSColors[:link].must_equal '39;49'
      end

      it 'must catch errors from malformed input and continue' do
        assert_raises StandardError do
          Haus::LSColors.parse "di=foo;\007,ln=bar;\001", :gnu
          Haus::LSColors.parse((0x00..0x7f).map { |n| n.chr }.join, :bsd) # Extra parens needed for 1.8.x
          raise StandardError
        end
      end

      it 'must produce default values for all types' do
        colors = Haus::LSColors.instance_variable_get :@colors
        %w[
          directory link socket fifo executable blockSpecial characterSpecial
          setuid setgid stickyOtherWritable otherWritable
        ].map { |t| colors[t.to_sym] }.all?.must_equal true
      end

      it 'must correctly parse GNU and BSD style color formats' do
        # TODO
      end
    end

    describe :private do
      describe :gnu do
        # TODO
      end

      describe :bsd do
        # TODO
      end
    end
  end
end
