require 'audit/audit_helper'
require 'audit/version'
require 'audit/model_helpers'
require 'audit/userstamp'
require 'audit/google_cloud'
require 'audit/configuration'
require 'audit/database/database'


module Audit
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
