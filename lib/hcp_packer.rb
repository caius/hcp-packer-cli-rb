# frozen_string_literal: true

module HCPPacker
  def self.config
    @config ||= Config.new
  end
end
