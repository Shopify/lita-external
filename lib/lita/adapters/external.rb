module Lita
  module Adapters
    class External < Adapter
      def initialize(*)
        super
        @redis = Redis::Namespace.new('messages', redis: robot.redis)
      end

      def real_adapter
        raise NotImplementedError, 'You need to instanciate the real adapter'
      end

      # Starts the connection.
      def run
        return if @running || @stopping

        @running = true
        @stopping = false
        until @stopping
          if result = redis.blpop('inbound', timeout: 1)
            handle_inbound_message(result.last)
          end
        end
      end

      def send_messages(target, strings)
        rpc(:send_messages, target, strings)
      end

      def set_topic(target, topic)
        rpc(:set_topic, target, topic)
      end

      def shut_down
        return unless @running

        @stopping = true
        robot.trigger(:disconnected)
      end

      private

      def handle_inbound_message(payload)
        message = Marshal.load(payload)
        robot.receive(message)
      rescue => error
        robot.config.robot.error_handler.call(error)
      end

      def rpc(method, *args)
        redis.rpush('outbound', Marshal.dump([method, args]))
      end
    end

    Lita.register_adapter(:external, External)
  end
end

