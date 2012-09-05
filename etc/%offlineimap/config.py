# encoding: utf-8

import commands

def keychain_password(host, user):
    cmd = """/usr/bin/security find-internet-password -g -s %s -a %s 2>&1 | ruby -e '
                 puts $stdin.read[/password:.*"(.*)"/, 1].gsub(/\\\\\\d{3}/) { |e|
                     [e.delete("\\\\").to_i(8)].pack "U"
                 }
          '""" % (host, user)
    return commands.getoutput(cmd)
