#!/usr/bin/ruby
#
# @file Launcher
#
# @copyright (c) 2010-2011, Christoph Kappel <unexist@dorfelite.net>
# @version $Id$
#
# This program can be distributed under the terms of the GNU GPLv2.
# See the file COPYING for details.
#
# Launcher that combines modes/tagging of subtle and a browser search bar.
#
# It opens uris with your default browser via xdg-open. Easiest way to set
# it is to define $BROWSER in your shell rc files.
#
# Thanks, fauno, for your initial work!
#
# Examples:
#
# :urxvt                - Call methods defined in the config
# g subtle wm           - Change to browser view and search for 'subtle wm' via Google
# urxvt @editor         - Open urxvt on view @editor with random tag
# urxvt @editor #work   - Open urxvt on view @editor with tag #work
# urxvt #work           - Open urxvt and tag with tag #work
# urxvt -urgentOnBell   - Open urxvt with the urgentOnBell option
# +urxvt                - Open urxvt and set full mode
# ^urxvt                - Open urxvt and set floating mode
# *urxvt                - Open urxvt and set sticky mode
# =urxvt                - Open urxvt and set zaphod mode
# urx<Tab>              - Open urxvt (tab completion)
#
# http://subforge.org/projects/subtle-contrib/wiki/Launcher
#

require 'singleton'
require 'uri'

begin
  require 'subtle/subtlext'
rescue LoadError
  puts ">>> ERROR: Couldn't find subtlext"
  exit
end

# Check for subtlext version
major, minor, teeny = Subtlext::VERSION.split('.').map(&:to_i)
if major == 0 and minor == 10 and 3104 > teeny
  puts ">>> ERROR: launcher needs at least subtle `0.10.3104' (found: %s)" % [
    Subtlext::VERSION
   ]
  exit
end

begin
  require_relative 'levenshtein.rb'
rescue LoadError => err
  puts ">>> ERROR: Couldn't find `levenshtein.rb'"
  exit
end

# Launcher class
module Subtle # {{{
  module Contrib # {{{
    # Precompile regexps
    RE_COMMAND = Regexp.new(/^([+\^\*]*[A-Za-z0-9_\-\/''\s]+)(\s[@#][A-Za-z0-9_-]+)*$/)
    RE_MODES   = Regexp.new(/^([+\^\*]*)([A-Za-z0-9_\-\/''\s]+)/)
    RE_SEARCH  = Regexp.new(/^[gs]\s+(.*)/)
    RE_METHOD  = Regexp.new(/^[:]\s*(.*)/)
    RE_URI     = Regexp.new(/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix)
    RE_BROWSER = Regexp.new(/(chrom[e|ium]|iron|navigator|firefox|opera)/i)

    # Launcher class
    class Launcher # {{{
      include Singleton

      # Default values
      @@font_big   = '-*-*-medium-*-*-*-40-*-*-*-*-*-*-*'
      @@font_small = '-*-*-medium-*-*-*-14-*-*-*-*-*-*-*'
      @@paths      = '/usr/bin'
      @@screen_num = 0

      # Singleton methods

      ## fonts {{{
      # Set font strings
      # @param [Array]  fonts  Fonts array
      ##

      def self.fonts=(fonts)
        if fonts.is_a?(Array)
          @@font_big   = fonts.first if(1 <= fonts.size)
          @@font_small = fonts.last  if(2 <= fonts.size)
        end
      end # }}}

      ## paths {{{
      # Set launcher path separated by colons
      # @param [String, Array]  paths  Path list separated by colon or array
      ##

      def self.paths=(paths)
        if paths.is_a?(String)
          @@paths = paths
        elsif paths.is_a?(Array)
          @@paths = paths.join(':')
        end
      end # }}}

      ## browser_screen_num {{{
      # Set screen num to show browser view
      # @param [Fixnum]  num  Screen number
      ##

      def self.browser_screen_num=(num)
        @screen_num = num if num.is_a?(Fixnum)
      end # }}}

      ## run {{{
      # Run the launcher
      # @param [String]  command  Command
      ##

      def self.run(command = nil)
        self.instance.run(command)
      end # }}}

      # Instance methods

      ## initialize {{{
      # Create launcher instance
      ##

      def initialize
        @candidate = nil
        @browser   = nil
        @view      = nil
        @x         = 0
        @y         = 0
        @width     = 0
        @height    = 0

        # Parsed data
        @parsed_tags  = []
        @parsed_views = []
        @parsed_app   = ''
        @parsed_modes = ''

        # Cached data
        @cached_tags   = Subtlext::Tag.all.map(&:name)
        @cached_views  = Subtlext::View.all.map(&:name)
        @cached_apps   = {}

        # FIXME: Find config instance
        if defined?(Subtle::Config)
          ObjectSpace.each_object(Subtle::Config) do |c|
            @cached_sender  = c
            @cached_methods = c.methods(false).map(&:to_s)
          end
        end

        # Something close to a skiplist
        @@paths.split(':').each do |path|
          if Dir.exist?(path)
            Dir.foreach(File.expand_path(path)) do |entry|
              file = File.basename(entry)
              sym  = file[0].to_sym

              # Sort in
              if @cached_apps.has_key?(sym)
                @cached_apps[sym] << file
              else
                @cached_apps[sym] = [ file ]
              end
            end
          else
            puts ">>> ERROR: Skipping non-existing path `%s'" % [ path ]
          end
        end

        # Init for performance
        @array1 = Array.new(20, 0)
        @array2 = Array.new(20, 0)

        # Get colors
        colors = Subtlext::Subtle.colors

        # Create input window
        @input = Subtlext::Window.new(:x => 0, :y => 0,
            :width => 1, :height => 1) do |w|
          w.name        = 'Launcher: Input'
          w.font        = @@font_big
          w.foreground  = colors[:focus_fg]
          w.background  = colors[:focus_bg]
          w.border_size = 0
        end

        # Get font height and y offset of input window
        @font_height1 = @input.font_height + 6
        @font_y1      = @input.font_y

        # Input handler
        @input.input do |string|
          begin
            Launcher.instance.parse(string)
          rescue => err
            puts err, err.backtrace
          end
        end

        # Completion handler
        @input.completion do |string, guess|
          begin
            Launcher.instance.complete(string, guess)
          rescue => err
            puts err, err.backtrace
          end
        end

        # Create info window
        @info  = Subtlext::Window.new(:x => 0, :y => 0,
            :width => 1, :height => 1) do |w|
          w.name        = 'Launcher: Info'
          w.font        = @@font_small
          w.foreground  = colors[:stipple]
          w.background  = colors.has_key?(:panel_top) ?
            colors[:panel_top] : colors[:panel]
          w.border_size = 0
        end

        # Get font height and y offset of info window
        @font_height2 = @info.font_height + 6
        @font_y2      = @info.font_y

        info
      end # }}}

      ## parse {{{
      # Parse input
      # @param  [String]  string  Input string
      # @param  [Bool]    notify  Show info messages
      ##

      def parse(string, notify = true)
        # Clear info field
        if string.empty? or string.nil?
          info
          return
        end

        # Check input
        if RE_URI.match(string)
          @candidate = URI.parse(string)

          info('Goto %s' % [ @candidate.to_s ]) if notify
        elsif RE_SEARCH.match(string)
          @candidate = URI.parse(
            'http://www.google.com/#q=%s' % [ URI.escape($1) ]
          )

          info('Goto %s' % [ @candidate.to_s ]) if notify
        elsif RE_METHOD.match(string)
          @candidate = $1.to_sym

          info('Call :%s' % [ @candidate ])
        elsif RE_COMMAND.match(string)
          @candidate    = string
          @parsed_tags  = []
          @parsed_views = []
          @parsed_app   = ''
          @parsed_modes = ''

          # Parse args
          @candidate.split.each do |arg|
            case arg[0]
              when '#' then @parsed_tags  << arg[1..-1]
              when '@' then @parsed_views << arg[1..-1]
              when '+', '^', '*'
                app, @parsed_modes, @parsed_app = RE_MODES.match(arg).to_a
              else
                if @parsed_app.empty?
                  @parsed_app += arg
                else
                  @parsed_app += ' ' + arg
                end
            end
          end

          # Add an ad-hoc tag if we don't have any and need one
          if @parsed_views.any? and not @parsed_app.empty? and
              @parsed_tags.empty?
            @parsed_tags << 'tag_%d' % [ rand(1337) ]
          end

          if notify
            if @parsed_views.any?
              info('Launch %s%s on %s (via %s)' % [
                modes2text(@parsed_modes),
                @parsed_app,
                @parsed_views.join(', '),
                @parsed_tags.join(', ')
              ])
            elsif @parsed_tags.any?
              info('Launch %s%s (via %s)' % [
                modes2text(@parsed_modes),
                @parsed_app,
                @parsed_tags.join(', ')
              ])
            else
              info('Launch %s%s' % [ modes2text(@parsed_modes), @parsed_app ])
            end
          end
        end
      end # }}}

      ## complete {{{
      # Complete string
      # @param  [String]  string  String to match
      # @param  [Fixnum]  guess   Number of guess
      ##

      def complete(string, guess)
        begin
          guesses = []
          lookup = nil

          # Clear info field
          if(string.empty? or string.nil?)
            info
            return
          end

          # Select lookup cache
          last = string.split(' ').last rescue string
          case last[0]
            when '#'
              lookup = @cached_tags
              prefix = '#'
            when '@'
              lookup = @cached_views
              prefix = '@'
            when ':'
              lookup = @cached_methods
              prefix = ':'
            when '+', '^', '*'
              lookup = @cached_apps[last[@parsed_modes.size].to_sym]
              prefix = @parsed_modes
            else
              lookup = @cached_apps[last[0].to_sym]
              prefix = ''
          end

          # Collect guesses
          unless lookup.nil?
            lookup.each do |l|
              guesses << [
                '%s%s' %[ prefix, l ],
                Levenshtein::distance(last.gsub(/^[@#:]/, ''),
                  l, 1, 5, 5, @array1, @array2)
              ]
            end

            guesses.sort! { |a, b| a[1] <=> b[1] } # Sort by distance

            @candidate = retval = guesses[guess].first

            # Convert to symbol if methods are guessed
            @candidate = @candidate.delete(':').to_sym if(':' == prefix)

            retval
          end
        rescue => err
          puts err, err.backtrace
        end
      end # }}}

      ## move {{{
      # Move launcher windows to current screen
      ##

      def move
        # Geometry
        geo     = Subtlext::Screen.current.geometry
        @width  = geo.width * 80 / 100
        @x      = geo.x + ((geo.width - @width) / 2)
        @y      = geo.y + geo.height - @font_height1 - @font_height2 - 40

        @input.geometry = [ @x, @y, @width, @font_height1 ]
        @info.geometry  = [ @x, @y + @font_height1, @width, @font_height2 ]
      end # }}}

      ## show {{{
      # Show launcher
      ##

      def show
        move

        @input.show
        @info.show

        info
      end # }}}

      ## hide # {{{
      # Hide launcher
      ##

      def hide
        @input.hide
        @info.hide
      end # }}}

      ## run {{{
      # Show and run launcher
      # @param [String]  command  Command
      ##

      def run(command = nil)
        # Run launcher when no command is given
        if command.nil?
          show
          command = @input.read(2, @font_y1, @width / 45)
          hide
        else
          parse(command)
        end

        # Check if input returns a value
        unless command.nil?
          case @candidate
            when Symbol #{{{
              @cached_sender.send(@candidate) # }}}
            when String # {{{
              # Find or create tags
              @parsed_tags.map! do |t|
                tag = Subtlext::Tag.first(t) || Subtlext::Tag.new(t)
                tag.save

                tag
              end

              # Find or create view and add tag
              @parsed_views.each do |v|
                view = Subtlext::View.first(v) || Subtlext::View.new(v)
                view.save

                view.tag(@parsed_tags) unless(view.nil? or @parsed_tags.empty?)
              end

              # Spawn app, tag it and set modes
              unless (client = Subtlext::Subtle.spawn(@parsed_app)).nil?
                client.tags  = @parsed_tags unless(@parsed_tags.empty?)

                # Set modes
                unless @parsed_modes.empty?
                  flags = []

                  # Translate modes
                  @parsed_modes.each_char do |c|
                    case c
                      when '+' then flags << :full
                      when '^' then flags << :float
                      when '*' then flags << :stick
                      when '=' then flags << :zaphod
                    end
                  end

                  client.flags = flags
                end
              end # }}}
            when URI # {{{
              find_browser

              unless @browser.nil?
                Subtlext::Screen[@@screen_num].view = @view
                system("xdg-open '%s' &>/dev/null" % [ @candidate.to_s ])
                @browser.focus
              end # }}}
          end
        end

        @candidate = nil
      end # }}}

      private

      def modes2text(modes) # {{{
        ret = []

        # Collect mode verbs
        modes.each_char do |c|
          case c
            when '+' then ret << 'full'
            when '^' then ret << 'floating'
            when '*' then ret << 'sticky'
            when '=' then ret << 'zaphod'
          end
        end

        ret.any? ? '%s ' % [ ret.join(', ') ] : ''
      end # }}}

      def find_browser # {{{
        begin
          if @browser.nil?
            Subtlext::Client.all.each do |c|
              if c.klass.match(RE_BROWSER)
                @browser = c
                @view    = c.views.first
                return
              end
            end

            puts '>>> ERROR: No supported browser found'
            puts '           (Supported: Chrome, Firefox and Opera)'
          end
        rescue
          @browser = nil
          @view    = nil
        end
      end # }}}

      def info(string = 'Nothing selected') # {{{
        @info.write(2, @font_y2, string)
        @info.redraw
      end # }}}
    end # }}}
  end # }}}
end # }}}

# Implicitly run
if __FILE__ == $0
  # Set fonts
  #Subtle::Contrib::Launcher.fonts = [
  #  'xft:DejaVu Sans Mono:pixelsize=80:antialias=true',
  #  'xft:DejaVu Sans Mono:pixelsize=12:antialias=true'
  #]

  # Set paths
  # Subtle::Contrib::Launcher.paths = [ '/usr/bin', '~/bin' ]

  # Set browser screen
  Subtle::Contrib::Launcher.browser_screen_num = 0

  Subtle::Contrib::Launcher.run
end

# vim:ts=2:bs=2:sw=2:et:fdm=marker
