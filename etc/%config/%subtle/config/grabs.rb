#
# == Grabs
#
# Grabs are keyboard and mouse actions within subtle, every grab can be
# assigned either to a key and/or to a mouse button combination. A grab
# consists of a chain and an action.
#
# === Finding keys
#
# The best resource for getting the correct key names is
# */usr/include/X11/keysymdef.h*, but to make life easier here are some hints
# about it:
#
# * Numbers and letters keep their names, so *a* is *a* and *0* is *0*
# * Keypad keys need *KP_* as prefix, so *KP_1* is *1* on the keypad
# * Strip the *XK_* from the key names if looked up in
#   /usr/include/X11/keysymdef.h
# * Keys usually have meaningful english names
# * Modifier keys have special meaning (Alt (A), Control (C), Meta (M),
#   Shift (S), Super (W))
#
# === Chaining
#
# Chains are a combination of keys and modifiers to one or a list of keys
# and can be used in various ways to trigger an action. In subtle, there are
# two ways to define chains for grabs:
#
#   1. *Default*: Add modifiers to a key and use it for a grab
#
#      *Example*: grab "W-Return", "urxvt"
#
#   2. *Chain*: Define a list of grabs that need to be pressed in order
#
#      *Example*: grab "C-y Return", "urxvt"
#
# ==== Mouse buttons
#
# [*B1*] = Button1 (Left mouse button)
# [*B2*] = Button2 (Middle mouse button)
# [*B3*] = Button3 (Right mouse button)
# [*B4*] = Button4 (Mouse wheel up)
# [*B5*] = Button5 (Mouse wheel down)
#
# ==== Modifiers
#
# [*A*] = Alt key
# [*C*] = Control key
# [*M*] = Meta key
# [*S*] = Shift key
# [*W*] = Super (Windows) key
#
# === Action
#
# An action is something that happens when a grab is activated, this can be one
# of the following:
#
# [*symbol*] Run a subtle action
# [*string*] Start a certain program
# [*array*]  Cycle through gravities
# [*lambda*] Run a Ruby proc
#
# === Example
#
# This will create a grab that starts a urxvt when Alt+Enter are pressed:
#
#   grab "A-Return", "urxvt"
#   grab "C-a c",    "urxvt"
#
# === Link
#
# http://subforge.org/projects/subtle/wiki/Grabs
#

(1..4).each do |n|
  # Switch to view
  grab "W-#{n}", "ViewJump#{n}".to_sym

  # Retag (move) client to view
  grab "W-S-#{n}" do |this|
    this.toggle_stick if this.is_stick?
    this.tags = [Subtlext::Tag.all.find { |t| t.name == n.to_s }]
  end
end

# In case no numpad is available e.g. on notebooks
grab 'W-C-q', [:top_left,     :top_left66,     :top_left33    ]
grab 'W-C-w', [:top,          :top66,          :top33         ]
grab 'W-C-e', [:top_right,    :top_right66,    :top_right33   ]
grab 'W-C-a', [:left,         :left66,         :left33        ]
grab 'W-C-s', [:center,       :center66,       :center33      ]
grab 'W-C-d', [:right,        :right66,        :right33       ]
grab 'W-C-z', [:bottom_left,  :bottom_left66,  :bottom_left33 ]
grab 'W-C-x', [:bottom,       :bottom66,       :bottom33      ]
grab 'W-C-c', [:bottom_right, :bottom_right66, :bottom_right33]

# Select adjacent windows
grab 'W-C-h', :ViewPrev
grab 'W-C-j', :ViewNext
grab 'W-C-k', :ViewPrev
grab 'W-C-l', :ViewNext

# Switch window focus in current view
%w[W-Tab W-S-Tab].each_with_index do |key, i|
  grab key do |this|
    clients = Subtlext::Client.visible + Subtlext::Client.all.select(&:is_stick?)
    window = eval %Q(clients.%s.find { |c| c.id %s this.id } || clients.%s) % (i.zero? ? %w[to_a > first] : %w[reverse < last])
    window.focus
  end
end

# Raise window
grab 'W-C-f', :WindowRaise

# Toggle sticky mode of window (will be visible on all views)
grab 'W-C-g', :WindowStick

# Check and reload config
grab 'W-C-r' do
  Subtlext::Subtle.reload if config_valid?
end

# Check and restart config
grab 'W-C-t' do
  Subtlext::Subtle.restart if config_valid?
end

# Toggle fullscreen mode of window
grab 'W-C-space', :WindowFull

# Quit subtle
grab 'W-Escape', :SubtleQuit

# Kill current window
grab 'W-q', :WindowKill

# Move current window
grab 'W-B1', :WindowMove

# Resize current window
grab 'W-B3', :WindowResize

# Applications
grab 'F9',    'rxvt-unicode --client'
grab 'W-F9',  'rxvt-unicode --client -- -e vim'
grab 'A-F9',  'rxvt-unicode --client -- -e tmuxlaunch -x'
grab 'F10',   'chrome'
grab 'W-F10', 'firefox'
grab 'A-F10', 'chrome --incognito'


### Sublets

# Launcher
grab 'W-space' do
  Subtle::Contrib::Launcher.run
end

# Volume
grab 'F3', :VolumeToggle
grab 'F4', :VolumeLower
grab 'F5', :VolumeRaise
