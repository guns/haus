require 'spec_helper'

describe "perl" do
  let(:filename) { 'test.pl' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  specify "if-clauses" do
    set_file_contents 'print "a = $a\n" if $debug;'

    split

    assert_file_contents <<-EOF
      if ($debug) {
        print "a = $a\\n";
      }
    EOF

    join

    assert_file_contents 'print "a = $a\n" if $debug;'
  end

  specify "and/or control flow" do
    set_file_contents 'open PID, ">", $pidfile or die;'

    split

    assert_file_contents <<-EOF
      unless (open PID, ">", $pidfile) {
        die;
      }
    EOF

    join

    assert_file_contents 'die unless open PID, ">", $pidfile;'
  end

  specify "hashes" do
    set_file_contents "my $info = {name => $name, age => $age};"

    split

    assert_file_contents <<-EOF
      my $info = {
        name => $name,
        age => $age,
      };
    EOF

    join

    assert_file_contents "my $info = {name => $name, age => $age};"
  end
end
