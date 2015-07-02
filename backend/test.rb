#!/usr/bin/env ruby

require 'minitest/autorun'
require 'json'

class TestDrivy < Minitest::Test
  (1..2).each do |level|
    define_method("test_level#{level}") do
      run_level level
    end
  end

  private

  def run_level(level)
    Dir.chdir "level#{level}" do
      expected = JSON.load File.read "output.json"
      result   = JSON.parse `ruby main.rb data.json`
      assert_equal expected, result
    end
  end
end
