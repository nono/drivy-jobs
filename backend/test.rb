#!/usr/bin/env ruby

require 'minitest/autorun'
require 'json'

class TestDrivy < Minitest::Test
  def test_level1
    Dir.chdir "level1" do
      expected = JSON.load File.read "output.json"
      result   = JSON.parse `ruby main.rb data.json`
      assert_equal expected, result
    end
  end
end
