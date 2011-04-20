# -*- encoding: utf-8 -*-

require 'csv'

unless $warned
  $warned = true

  puts <<EOM
WARNING: This test suite requires a real Unix user account with a home
WARNING: directory writable by the current user. The name of the testing user
WARNING: is `test' by default, and can be changed by setting ENV['TEST_USER']
WARNING:
WARNING: All the files in the test user's home directory are at risk of being
WARNING: modified or destroyed.

EOM

  # FasterCSV became CSV 2.0 in ruby 1.9
  col_sep = CSV.const_get(:VERSION) < '2.0.0' ? ':' : { :col_sep => ':' }
  $user = ENV['TEST_USER'] || 'TEST'
  $home = case RUBY_PLATFORM
  when /darwin/
    # OS X's handy `id -P' appeared in 10.3
    entry = CSV.parse(%x(id -P #{$user} 2>/dev/null), col_sep).first
    entry[-2] if entry
  else
    # Standard /etc/passwd routine
    entry = CSV.parse(File.read('/etc/passwd'), col_sep).find { |r| r.first == $user }
    entry[-2] if entry
  end

  abort "No home directory for user #{$user.inspect}" unless $home and File.directory? $home
  abort "No permissions to write #{$home.inspect}" unless File.writable? $home
end
