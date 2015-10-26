require 'lita'

require 'lita/external/version'
require 'lita/external/robot'
require 'lita/external/cli'
require 'lita/adapters/external'

module Lita
  module External
    extend self

    # It's important to use another redis connection than Lita's one, because we are using long blocking calls
    # and redis use a mutex around these
    def blocking_redis
      @blocking_redis ||= Redis::Namespace.new(Lita::REDIS_NAMESPACE, redis: Redis.new(Lita.config.redis))
    end

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
