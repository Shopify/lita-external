require 'zk'

module Lita
  module External
    class Robot < ::Lita::Robot

      def initialize_leader_lock
        return unless ENV['ZOOKEEPER_PEERS']
        zk_peers = ENV['ZOOKEEPER_PEERS']
        zk_lock = "lita_#{config.robot.name}_#{ENV['ENV']}"
        @locker = ZK::Locker.exclusive_locker(ZK.new(zk_peers), zk_lock)
        @locker.lock(wait: false)
      end

      def receive(message)
        process_message = true
        process_message = @locker.locked? if @locker
        if process_message
          Lita.logger.info("Put inbound message to #{message.user.mention_name} into the queue")
          Lita.redis.rpush('messages:inbound', External.dump_message(message))
        else
          Lita.logger.info("Skipping inbound message to #{message.user.mention_name}")
        end
      end

      def run
        @stopping = false

        trigger(:master_loaded)

        watch_outbound_queue
        super
      end

      def shut_down
        @stopping = true
        super
      end

      def watch_outbound_queue
        Thread.start do
          Lita.logger.info("Watching outbound queue")
          until @stopping
            begin
              if command = External.blocking_redis.blpop('messages:outbound', timeout: 1)
                process_outbound_command(command.last)
              end
            rescue => error
              Lita.logger.error("Outbound message failed: #{error.class}: #{error.message}")
              if Lita.config.robot.error_handler
                Lita.config.robot.error_handler.call(error)
              end
            end
          end
        end
      end

      def process_outbound_command(payload)
        command, args = Marshal.load(payload)
        Lita.logger.debug("Triggering #{command}")
        adapter.public_send(command, *args)
      end
    end
  end
end
