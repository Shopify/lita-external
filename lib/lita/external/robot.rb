module Lita
  module External
    class Robot < ::Lita::Robot

      class Ballot
        attr_accessor :veto
        def initialize
          @veto = false
        end
      end

      def receive(message)
        ballot = Ballot.new
        trigger(:master_receive, ballot: ballot)
        if ballot.veto
          Lita.logger.debug("Ignoring vetoed message")
        else
          Lita.logger.debug("Put inbound message from #{message.user.mention_name} into the queue")
          Lita.redis.rpush('messages:inbound', External.dump_message(message))
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
              if payload = External.blocking_redis.blpop('messages:outbound', timeout: 1)
                command, args = Marshal.load(payload.last)
                Lita.logger.debug("Triggering #{command}")
                adapter.public_send(command, *args)
              end
            rescue => error
              Lita.logger.error("Outbound message failed: #{error.class}: #{error.message}")
              Lita.logger.debug { "Outbound message failed: command=#{command} args=#{args.inspect}" }
              if Lita.config.robot.error_handler
                Lita.config.robot.error_handler.call(error)
              end
            end
          end
        end
      end
    end
  end
end
