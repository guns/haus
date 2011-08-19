
#          /)   /)          /)
#   _     (/_/_// _     __ (/_
#  /_)(_(/_)(_(/_(/_ . / (/_)
#
#   guns <self@sungpae.com>


$:.push File.expand_path('../lib', __FILE__)

require 'launcher'

def config type
  eval File.read(File.expand_path "../config/#{type}.rb", __FILE__)
end

def config_valid?
  config  = File.expand_path __FILE__
  sublets = File.expand_path '../sublets', __FILE__
  system *%W[subtle --check --config=#{config} --sublets=#{sublets}]
end

config :options
config :screen
config :styles
config :gravities
config :grabs
config :tags
config :views
config :sublets
config :hooks
