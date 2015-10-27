module Lita
  module Adapters
    class External < Adapter
      config :min_threads
      config :max_threads
      def initialize(*)
        super
        @thread_pool = ::Puma::ThreadPool.new((config.min_threads || 8).to_i, (config.max_threads || 16).to_i) do |message|
          log.debug("processing inbound message from: #{message.user.mention_name}")
          robot.receive(message)
        end
      end

      def real_adapter
        raise NotImplementedError, 'You need to instanciate the real adapter'
      end

      # Starts the connection.
      def run
        return if @running || @stopping

        @running = true
        @stopping = false
        log.info("Listening to redis queue: `messages:inbound`")
        until @stopping
          begin
            if result = Lita::External.blocking_redis.blpop('messages:inbound', timeout: 1)
              handle_inbound_message(result.last)
            end
          rescue => error
            Lita.logger.error("Inbound message failed: #{error.class}: #{error.message}")
            Lita.config.robot.error_handler(error)
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

        log.info("Shutting down")
        @stopping = true
        @thread_pool.shutdown
        robot.trigger(:disconnected)
      end

      private

      def handle_inbound_message(payload)
        message = ::Lita::External.load_message(payload, robot: robot)
        log.debug("enqueuing inbound message from: #{message.user.mention_name}")
        @thread_pool << message
      end

      def rpc(method, *args)
        Lita.logger.info("Putting outbound message into the queue: #{method}(#{args.map(&:inspect).join(', ')})")
        Lita.redis.rpush('messages:outbound', Marshal.dump([method, args]))
      end
    end

    Lita.register_adapter(:external, External)
  end
end

