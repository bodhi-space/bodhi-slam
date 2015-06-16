require 'simplecov'
SimpleCov.start do
  add_group "Errors", "lib/bodhi-slam/errors"
  add_group "Validators", "lib/bodhi-slam/validators"
  add_filter "/spec/"
end

require 'bundler/setup'
Bundler.setup

require 'bodhi-slam'

require 'dotenv'
Dotenv.load

RSpec.configure do |config|
  # Only use the new 'expect' syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end