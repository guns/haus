require 'spec_helper'

describe "python" do
  let(:vim) { VIM }
  let(:filename) { 'test.py' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 4)
  end

  specify "dictionaries" do
    set_file_contents "spam = {'spam': [1, 2, 3], 'spam, spam': 'eggs'}"

    vim.search '{'
    split

    assert_file_contents <<-EOF
      spam = {
              'spam': [1, 2, 3],
              'spam, spam': 'eggs'
              }
    EOF

    join

    assert_file_contents "spam = {'spam': [1, 2, 3], 'spam, spam': 'eggs'}"
  end

  specify "lists" do
    set_file_contents 'spam = [1, [2, 3], 4]'

    vim.search '[1'
    split

    assert_file_contents <<-EOF
      spam = [1,
              [2, 3],
              4]
    EOF

    join

    assert_file_contents 'spam = [1, [2, 3], 4]'
  end

  specify "imports" do
    set_file_contents 'from foo import bar, baz'

    split

    assert_file_contents <<-EOF
      from foo import bar,\\
              baz
    EOF

    join

    assert_file_contents 'from foo import bar, baz'
  end

  specify "statements" do
    set_file_contents 'while True: loop()'

    split

    assert_file_contents <<-EOF
      while True:
          loop()
    EOF

    join

    assert_file_contents 'while True: loop()'
  end
end
