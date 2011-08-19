# Notify sublet file
# Created with sur-0.2.168
require "ffi"

# Message class
class Message # {{{
  # Message id
  attr_reader :id

  # Icon for message
  attr_reader :icon

  # Summary of the message
  attr_reader :summary

  # Body of the message
  attr_reader :body

  # Message timeout
  attr_reader :timeout

  ## initialize {{{
  # Create a new message
  # @param [String]  summary  Message summary
  # @param [String]  body     Message body
  # @param [String]  icon     Message icon
  # @param [Fixnum]  timeout  Message timeout
  ##

  def initialize(summary = "", body = "", icon = "", timeout = 0)
    @@id ||= 0

    # Add data
    @id      = @@id
    @summary = summary
    @body    = body
    @icon    = icon
    @timeout = timeout

    # Increase message count
    @@id += 1
  end # }}}
end # }}}

# DBus interface
class DBus # {{{
  extend FFI::Library

  ffi_lib("libdbus-1")

  # DBus name
  DBUS_NAME  = "org.freedesktop.Notifications"

  # DBus path
  DBUS_PATH  = "/org/freedesktop/Notifications"

  # DBus interface
  DBUS_IFACE = "org.freedesktop.Notifications"

  # DBus filter
  DBUS_FILTER = "path='#{DBUS_PATH}', interface='#{DBUS_IFACE}'"

  # DBus connection file descriptor
  attr_reader :fd

  # Notification messages
  attr_accessor :messages

  # Methods

  ## initialize {{{
  # Initialize the class
  # @return [Object] New #DBus object
  ###

  def initialize
    # Init error
    @error   = DBusError.new
    @lasterr = ""

    dbus_error_init(@error) #< Init error

    # Create connection
    @connection = dbus_bus_get(:bus_session, @error)

    raise "Couldn't connect to dbus" if(any_error?)

    # Request name and replace current owner
    reply = dbus_bus_request_name(@connection, DBUS_NAME,
      :flag_replace, @error)

    raise "Couldn't request notification interface" if(any_error?)

    # Check reply of request
    if(DBusRequestReply[:reply_primary] != reply)
      puts "Failed requesting ownership of `#{DBUS_NAME}': %s" % [
        case(reply)
          when 2 then "Service has been placed in queue"
          when 3 then "Service is already in queue"
          when 4 then "Service is already primary owner"
        end
      ]
    end

    # Get socket file descriptor
    pfd = FFI::MemoryPointer.new(:int)

    dbus_connection_get_unix_fd(@connection, pfd)

    @fd = pfd.null? ? 0 : pfd.read_int

    # Add message filter
    dbus_bus_add_match(@connection, DBUS_FILTER, @error)
    dbus_connection_flush(@connection)

    raise "Couldn't apply message filter" if(any_error?)

    @messages = []

    # Initially fetch
    fetch
  end # }}}

  ## fetch {{{
  # Fetch data from connection
  # @return [Bool] Whether fetch was successful
  ##

  def fetch
    ret = false

    dbus_connection_read_write(@connection, 0)

    mesg = dbus_connection_pop_message(@connection)

    # Check whether message is of desired type
    unless(mesg.null?)
      # UINT32 org.freedesktop.Notifications.Notify(
      #   STRING app_name, UINT32 replaces_id, STRING app_icon,
      #   STRING summary, STRING body, ARRAY actions, DICT hints,
      #   INT32 expire_timeout
      # )
      if(dbus_message_is_method_call(mesg, DBUS_IFACE, "Notify"))
        get_message(mesg)

        ret = true
      # void org.freedesktop.Notifications.GetServerInformation(
      #   out STRING name, out STRING vendor, out STRING version
      # )
      elsif(dbus_message_is_method_call(mesg, DBUS_IFACE,
          "GetServerInformation"))
        get_server_info(mesg)

        ret = false
      # STRING_ARRAY org.freedesktop.Notifications.GetCapabilities(void)
      elsif(dbus_message_is_method_call(mesg, DBUS_IFACE, "GetCapabilities"))
        get_capabilities(mesg)

        ret = false
      else
        fetch #< Repeat until we get something reasonable
      end
    end

    ret
  end # }}}

  ## kill {{{
  # Kill object
  ##

  def kill
    if(dbus_connection_get_is_connected(@connection))
      # Remove message filter
      dbus_bus_remove_match(@connection, DBUS_FILTER, nil)

      # Release name
      dbus_bus_release_name(@connection, DBUS_NAME, @error)

      any_error? #< Just ignore

      # Unref connection
      dbus_connection_flush(@connection)
      dbus_connection_unref(@connection)
    end
  end # }}}

  private

  def any_error? # {{{
    ret = false

    # Check if error is set
    if(dbus_error_is_set(@error))
      dbus_error_free(@error)

      ret = true
    end

    ret
  end # }}}

  def str2ptr(str) # {{{
    value = FFI::MemoryPointer.from_string(str)
    ptr   = FFI::MemoryPointer.new(:pointer)

    ptr.put_pointer(0, value)

    ptr
  end # }}}

  def iter2fixnum(iter) # {{{
    ret = 0

    begin
      pvalue = FFI::MemoryPointer.new(:int)

      dbus_message_iter_get_basic(iter, pvalue)
      dbus_message_iter_next(iter)

      ret = pvalue.null? ? 0 : pvalue.read_int
    rescue
      ret = 0
    end

    ret
  end # }}}

  def iter2string(iter) # {{{
    ret = ""

    # Get string part from iter
    begin
      pvalue = FFI::MemoryPointer.new(:pointer)

      dbus_message_iter_get_basic(iter, pvalue)
      dbus_message_iter_next(iter)

      svalue = pvalue.read_pointer

      ret = svalue.null? ? "" : svalue.read_string
    rescue
      ret = ""
    end

    ret
  end # }}}

  def get_message(mesg) # {{{
    # Create iter
    iter  = DBusMessageIter.new
    piter = iter.pointer
    dbus_message_iter_init(mesg, piter)

    # Collect data from message
    name    = iter2string(piter)
    replace = iter2fixnum(piter)
    icon    = iter2string(piter)
    summary = iter2string(piter)
    body    = iter2string(piter)

    # Ignore array and hints
    dbus_message_iter_next(piter)
    dbus_message_iter_next(piter)

    timeout = iter2fixnum(piter)

    # Create reply to mark message as read
    reply = dbus_message_new_method_return(mesg)
    pid   = FFI::MemoryPointer.new(:uint32)

    # Create iter
    iter  = DBusMessageIter.new
    piter = iter.pointer

    # Append data to iter
    dbus_message_iter_init_append(reply, piter)
    dbus_message_iter_append_basic(piter, :type_uint32, pid)
    dbus_connection_send(@connection, reply, nil)
    dbus_connection_flush(@connection)
    dbus_message_unref(reply)

    dbus_message_unref(mesg)

    # Append new message
    @messages << Message.new(summary, body, icon, timeout)
  end # }}}

  def get_server_info(mesg) # {{{
    # Create reply
    reply    = dbus_message_new_method_return(mesg)
    pname    = str2ptr("subtle")
    pvendor  = str2ptr("http://subtle.subforge.org")
    pversion = str2ptr("0.0")
    pspec    = str2ptr("0.9")

    # Create iter
    iter  = DBusMessageIter.new
    piter = iter.pointer

    dbus_message_iter_init_append(reply, piter)
    dbus_message_iter_append_basic(piter, :type_string, pname)
    dbus_message_iter_append_basic(piter, :type_string, pvendor)
    dbus_message_iter_append_basic(piter, :type_string, pversion)
    dbus_message_iter_append_basic(piter, :type_string, pspec)
    dbus_connection_send(@connection, reply, nil)
    dbus_connection_flush(@connection)
    dbus_message_unref(reply)
  end # }}}

  def get_capabilities(mesg) # {{{
    # Create reply
    reply = dbus_message_new_method_return(mesg)

    # Create iters
    iter  = DBusMessageIter.new
    piter = iter.pointer

    dataiter  = DBusMessageIter.new
    pdataiter = dataiter.pointer

    # Create array
    pbody = str2ptr("body")

    dbus_message_iter_init_append(reply, piter)
    dbus_message_iter_open_container(piter, :type_array,
      DBusType[:type_string].chr, pdataiter)
    dbus_message_iter_append_basic(pdataiter, :type_string, pbody)
    dbus_message_iter_close_container(piter, pdataiter)
    dbus_connection_send(@connection, reply, nil)
    dbus_connection_flush(@connection)
    dbus_message_unref(reply)
  end # }}}

 # Datatypes

  # DBusType {{{
  DBusBusType = enum(
  [
    :bus_session, 0,
    :bus_system,
    :bus_starter
  ]) # }}}

  # DBusOwnerFlags {{{
  DBusOwnerFlags = enum(
  [
    :flag_allow,    0x1,
    :flag_replace,  0x2,
    :flag_no_queue, 0x4
  ]) # }}}

  # DBusRequestReply {{{
  DBusRequestReply = enum(
  [
    :reply_primary,  1,
    :reply_in_queue, 2,
    :reply_exists,   3,
    :reply_owner,    4
  ]) # }}}

  # DBusType {{{
  DBusType = enum(
  [
    :type_int32,  "i".ord,
    :type_uint32, "u".ord,
    :type_string, "s".ord,
    :type_array,  "a".ord
  ]) # }}}

  # DBusError {{{
  class DBusError < FFI::Struct
    layout(
      :name,    :pointer,
      :message, :pointer,
      :dummy1,  :uint32,
      :dummy2,  :uint32,
      :dummy3,  :uint32,
      :dummy4,  :uint32,
      :dummy5,  :uint32,
      :pad,     :pointer
    )
  end # }}}

  # DBusMessageIter {{{
  class DBusMessageIter < FFI::Struct
    layout(
      :dummy1,  :pointer,
      :dummy2,  :pointer,
      :dummy3,  :uint32,
      :dummy4,  :int,
      :dummy5,  :int,
      :dummy6,  :int,
      :dummy7,  :int,
      :dummy8,  :int,
      :dummy9,  :int,
      :dummy10, :int,
      :dummy11, :int,
      :pad1,    :int,
      :pad2,    :int,
      :pad3,    :pointer
    )
  end # }}}

  # FFI

  ## dbus_error_init {{{
  # Init error struct
  # @param [Pointer]  error  A #DBusError
  ##

  attach_function(:dbus_error_init,
    :dbus_error_init, [ :pointer ], :void
  ) # }}}

  ## dbus_error_is_set {{{
  # Whether error is set
  # @param [Pointer]  error  A #DBusError
  ##

  attach_function(:dbus_error_is_set,
    :dbus_error_is_set, [ :pointer ], :bool
  ) # }}}

  ## dbus_error_free {{{
  # Free dbus error
  # @param [Pointer]  error  A #DBusError
  ##

  attach_function(:dbus_error_free,
    :dbus_error_free, [ :pointer ], :void
  ) # }}}

  ## dbus_bus_get {{{
  # Connect to bus daemon and register client
  # @param [Fixnum]   type   A #DBusBusType
  # @param [Pointer]  error  A #DBusError
  # @return [Pointer]  A #DBusConnection
  ##

  attach_function(:dbus_bus_get,
    :dbus_bus_get, [ DBusBusType, :pointer ], :pointer
  ) # }}}

  ## dbus_bus_request_name {{{
  # Ask bus to assign specific name
  # @param [Pointer]  connection  A #DBusConnection
  # @param [String]   name        Name to request
  # @param [Fixnum]   flags       Flags
  # @param [Pointer]  error       A #DBusError
  # @return [Fixnum] Result code, -1 if error is set
  ##

  attach_function(:dbus_bus_request_name,
    :dbus_bus_request_name, [ :pointer, :string, DBusOwnerFlags, :pointer ],
    :int
  ) # }}}

  ## dbus_bus_release_name {{{
  # Ask bus to release specific name
  # @param [Pointer]  connection  A #DBusConnection
  # @param [String]   name        Name to release
  # @param [Pointer]  error       A #DBusError
  ##

  attach_function(:dbus_bus_release_name,
    :dbus_bus_release_name, [ :pointer, :string, :pointer ], :void
  ) # }}}

  ## dbus_bus_add_match {{{
  # Add rule for messages to receive
  # @param [Pointer]  connection  A #DBusConnection
  # @param [String]   rule        Matching rule
  # @param [Poiner]   error       A #DBusError
  ##

  attach_function(:dbus_bus_add_match,
    :dbus_bus_add_match, [ :pointer, :string, :pointer ], :void
  ) # }}}

  ## dbus_bus_remove_match {{{
  # Remove rule for messages
  # @param [Pointer]  connection  A #DBusConnection
  # @param [String]   rule        Matching rule
  # @param [Poiner]   error       A #DBusError
  ##

  attach_function(:dbus_bus_remove_match,
    :dbus_bus_remove_match, [ :pointer, :string, :pointer ], :void
  ) # }}}

  ## dbus_connection_read_write {{{
  # Check connection for data
  # @param [Pointer]  connection            A #DBusConnection
  # @param [Fixnum]   timeout_milliseconds  Timeout in milliseconds
  # @return [Bool]  Whether data is available
  ##

  attach_function(:dbus_connection_read_write,
    :dbus_connection_read_write, [ :pointer, :int ], :bool
  ) # }}}

  ## dbus_connection_pop_message {{{
  # Pop message from connection
  # @param [Pointer]  connection  A #DBusConnection
  # @return [Bool]  Whether data is available
  ##

  attach_function(:dbus_connection_pop_message,
    :dbus_connection_pop_message, [ :pointer ], :pointer
  ) # }}}

  ## dbus_connection_get_unix_fd {{{
  # Get dbus connection socket fd
  # @param [Pointer]  connection  A #DBusConnection
  # @param [Pointer]  fd          Socket file descriptor
  # @return [Bool]  Whether this was successful
  ##

  attach_function(:dbus_connection_get_unix_fd,
    :dbus_connection_get_unix_fd, [ :pointer, :pointer ], :bool
  ) # }}}

  ## dbus_connection_get_is_connected {{{
  # Whether connection is currently open
  # @param [Pointer]  connection  A #DBusConnection
  ##

  attach_function(:dbus_connection_get_is_connected,
    :dbus_connection_get_is_connected, [ :pointer ], :bool
  ) # }}}

  ## dbus_connection_send {{{
  # Adds a message to the outgoing message queue
  # @param [Pointer]  connection  A #DBusConnection
  # @param [Pointer]  message     A #DBusMessage
  # @param [Pointer]  serial      Message serial
  # @return [Bool]  Whether this was successful
  ##

  attach_function(:dbus_connection_send,
    :dbus_connection_send, [ :pointer, :pointer, :pointer ], :bool
  ) # }}}

  ## dbus_connection_flush {{{
  # Flush data on connection
  # @param [Pointer]  connection  A #DBusConnection
  ##

  attach_function(:dbus_connection_flush,
    :dbus_connection_flush, [ :pointer ], :void
  ) # }}}

  ## dbus_connection_unref {{{
  # Unreference connection
  # @param [Pointer]  connection  A #DBusConnection
  ##

  attach_function(:dbus_connection_unref,
    :dbus_connection_unref, [ :pointer ], :void
  ) # }}}

  ## dbus_message_new_method_return {{{
  # Construct a reply to a method call
  # @param [Pointer]  message  A #DBusMessage
  # @return [Pointer] A #DbusMessage
  ##

  attach_function(:dbus_message_new_method_return,
    :dbus_message_new_method_return, [ :pointer ], :pointer
  ) # }}}

  ## dbus_message_iter_init {{{
  # Init message iter
  # @param [Pointer]  message  A #DBusMessage
  # @param [Pointer]  iter     A #DBusMessageIter
  # @return [Bool]  Whether init succeeded
  ##

  attach_function(:dbus_message_iter_init,
    :dbus_message_iter_init, [ :pointer, :pointer ], :bool
  ) # }}}

  ## dbus_message_iter_init_append {{{
  # Initializes a DBusMessageIter for appending arguments
  # @param [Pointer]  message  A #DBusMessage
  # @param [Pointer]  iter     A #DBusMessageIter
  ##

  attach_function(:dbus_message_iter_init_append,
    :dbus_message_iter_init_append, [ :pointer, :pointer ], :void
  ) # }}}

  ## dbus_message_iter_get_arg_type {{{
  # Get the argument type of the message iter
  # @param [Pointer]  iter  A #DBusMessageIter
  # @return [Fixnum] Argument type of iter
  ##

  attach_function(:dbus_message_iter_get_arg_type,
    :dbus_message_iter_get_arg_type, [ :pointer ], :int
  ) # }}}

  ## dbus_message_iter_next {{{
  # Get next iter
  # @param [Pointer]  iter  A #DBusMessageIter
  # @return [Bool]  Whether next succeeded
  ##

  attach_function(:dbus_message_iter_next,
    :dbus_message_iter_next, [ :pointer ], :bool
  ) # }}}

  ## dbus_message_iter_append_basic {{{
  # Appends a basic-typed value to the message
  # @param [Pointer]  iter   A #DBusMessageIter
  # @param [Fixnum]   type   A #DBusType
  # @param [Pointer]  value  Address of the value
  # @return [Bool] Whether append succeeded
  ##

  attach_function(:dbus_message_iter_append_basic,
    :dbus_message_iter_append_basic, [ :pointer, DBusType, :pointer ], :bool
  ) # }}}

  ## dbus_message_iter_append_fixed_array {{{
  # Appends a block of fixed-length values to an array
  # @param [Pointer]  iter        A #DBusMessageIter
  # @param [Fixnum]   type        A #DBusType
  # @param [Pointer]  value       Address of the array
  # @param [Fixnum]   n_elements  Number of elements to append
  # @return [Bool] Whether append succeeded
  ##

  attach_function(:dbus_message_iter_append_fixed_array,
    :dbus_message_iter_append_fixed_array,
    [ :pointer, DBusType, :pointer, :int ], :bool
  ) # }}}

  ## dbus_message_iter_get_basic {{{
  # Get basic value from message
  # @param [Pointer]  message  A #DBusMessage
  # @param [Pointer]  value    A value
  # @return [Bool]  Whether get value succeeded
  ##

  attach_function(:dbus_message_iter_get_basic,
    :dbus_message_iter_get_basic, [ :pointer, :pointer ], :bool
  ) # }}}

  ## dbus_message_iter_open_container {{{
  # Appends a container-typed value to the message
  # @param [Pointer]  iter                 A #DBusMessageIter
  # @param [Fixnum]   type                 A #DBusType
  # @param [String]   contained_signature  Type of container contents
  # @param [Pointer]  sub                  A #DBusMessageIter
  # @return [Bool] Whether get value succeeded
  ##

  attach_function(:dbus_message_iter_open_container,
    :dbus_message_iter_open_container,
    [ :pointer, DBusType, :string, :pointer ], :bool
  ) # }}}

  ## dbus_message_iter_close_container {{{
  # Closes a container-typed value to the message
  # @param [Pointer]  iter A #DBusMessageIter
  # @param [Pointer]  sub  A #DBusMessageIter
  # @return [Bool] Whether get value succeeded
  ##

  attach_function(:dbus_message_iter_close_container,
    :dbus_message_iter_close_container, [ :pointer, :pointer ], :bool
  ) # }}}

  ## dbus_message_is_method_call {{{
  # Check whether the mssage is a method call of given type
  # @param [Pointer]  message    A #DBusMessage
  # @param [String]   interface  Interface name
  # @param [String]   method     Method name
  # @return [Bool] Whether method call is of given type
  ##

  attach_function(:dbus_message_is_method_call,
    :dbus_message_is_method_call, [ :pointer, :string, :string ], :bool
  ) # }}}

  ## dbus_message_unref {{{
  # Unreference message
  # @param [Pointer]  message  A #DBusMessage
  ##

  attach_function(:dbus_message_unref,
    :dbus_message_unref, [ :pointer ], :void
  ) # }}}
end # }}}

# Sublet
configure :notify do |s| # {{{
  s.dbus = DBus.new

  # Get colors
  colors = Subtlext::Subtle.colors

  # Get config values
  font = s.config[:font] || 'xft:Menlo:pixelsize=12px'
  fg   = Subtlext::Color.new(s.config[:foreground] || colors[:sublets_fg])
  bg   = Subtlext::Color.new(s.config[:background] || colors[:sublets_bg])
  s.hl = Subtlext::Color.new(s.config[:highlight]  || colors[:focus_fg])

  # Icon
  s.iconify = lambda { |f| Subtlext::Icon.new File.expand_path("../icons/#{f}", __FILE__) }
  s.icon = s.iconify.call 'info.xbm'

  # Window
  s.win = Subtlext::Window.new(:x => 0, :y => 0, :width => 1, :height => 1) do |w|
    w.name        = "Sublet notify"
    w.font        = font
    w.foreground  = fg
    w.background  = bg
    w.border_size = 0
  end

  # Font metrics
  s.font_height = s.win.font_height
  s.font_y      = s.win.font_y

  # Watch socket
  s.watch(s.dbus.fd)

  s.data = s.icon.to_s
end # }}}

on :watch do |s| # {{{
  # Fetch messages
  s.dbus.fetch

  unless(s.dbus.messages.empty?)
    s.data = "%s%s" % [ s.hl, s.icon ]
  end
end # }}}

on :mouse_over do |s| # {{{
  # Show and print messages
  unless(s.dbus.messages.empty?)
    x      = 0
    y      = 0
    width  = 0
    height = 0

    s.win.clear

    # Write each message and calculate window width
    s.dbus.messages.each do |msg|
      buf = ":: #{msg.summary} ::\n" + msg.body.gsub(/(.{72})/, "\\1\n")
      buf.lines.each do |line|
        size    = s.win.write 2, height + s.font_y, line.chomp
        width   = size if size > width #< Get widest
        height += s.font_height
      end
    end

    # Orientation
    screen_geom = s.screen.geometry
    sublet_geom = s.geometry

    # X position
    if(sublet_geom.x + width > screen_geom.x + screen_geom.width)
      x = screen_geom.x + screen_geom.width - width #< x + width > screen width
    else
      x = sublet_geom.x #< Sublet x
    end

    # Y position
    if(sublet_geom.y + height > screen_geom.y + screen_geom.height)
      y = screen_geom.y + screen_geom.height - height #< Bottom
    else
      y = sublet_geom.y + sublet_geom.height #< Top
    end

    s.win.geometry = [ x, y, width, height ]

    s.win.show
  end
end # }}}

on :mouse_out do |s| # {{{
  # Hide window
  unless(s.dbus.messages.empty?)
    s.win.hide
    s.dbus.messages = []
    s.data          = s.icon.to_s
  end
end # }}}

on :unload do |s| # {{{
  # Tidy up
  s.win.kill unless(s.win.nil?)
  s.dbus.kill unless(s.dbus.nil?)
end # }}}
