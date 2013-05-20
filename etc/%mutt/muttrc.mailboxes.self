unmailboxes *
mailboxes $spoolfile $mbox $postponed \
          `ruby -r shellwords -e 'puts Dir[File.expand_path("~/Mail/self/*")].map(&:shellescape).join(" ")'`
