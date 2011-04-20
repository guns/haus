# -*- encoding: utf-8 -*-

module HausHelper
  def capture_fork_io
    out_rd, out_wr = IO.pipe
    err_rd, err_wr = IO.pipe

    pid = fork do
      out_rd.close
      err_rd.close
      $stdout.reopen out_wr
      $stderr.reopen err_wr
      yield
    end

    out_wr.close
    err_wr.close
    Process.wait pid
    [out_rd.read, err_rd.read]
  end
end

class Haus
  class Noop < Task
    desc 'This class does nothing'
    banner "This class does nothing; it's purpose is to ease automated testing."
  end
end
