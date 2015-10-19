require 'lita'

require 'lita/external/version'
require 'lita/external/robot'
require 'lita/external/cli'
require 'lita/adapters/external'

module Lita
  module External
    extend self

    def dump_message(message)
      # The robot instance contains Proc and other non serializable attributes
      # Also, it's a singleton and should be set again in the receiving process anyway
      message.instance_variable_set(:@robot, nil)
      Marshal.dump(message)
    end

    def load_message(payload, robot: )
      message = Marshal.load(payload)
      message.instance_variable_set(:@robot, robot)
      message
    end
  end
end
