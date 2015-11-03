require 'optparse'

module Lita
  module External
    module CLI
      extend self

      def parse_options(argv)
        config = {config_file: 'lita_config.rb'}
        parser = OptionParser.new do |opts|
          opts.banner = "Standalone daemon to run a lita adapter"
          opts.separator ""
          opts.separator "Usage: messenger [options]"
          opts.separator ""
          opts.separator "Main options:"

          opts.on("-c", "--config FILE", "Lita config file to load") do |file|
            config[:config_file] = File.expand_path(file)
          end

          opts.on("-a", "--adapter ADAPTER", "Lita adapter to use") do |adapter|
            config[:adapter] = adapter.to_sym
          end
        end

        parser.parse(argv)

        config
      end

      def load_lita_config(options)
        require options[:config_file]
      end

      def set_adapter(options)
        if options[:adapter]
          Lita.config.robot.adapter = options[:adapter]
        end

        if Lita.config.robot.adapter == :external || Lita.config.robot.adapter == 'external'
          STDERR.puts "You must specify the adapter to use"
          exit 1
        end

        begin
          require "lita-#{Lita.config.robot.adapter}"
        rescue LoadError
        end
      end

      def run(argv)
        options = parse_options(argv)
        load_lita_config(options)
        set_adapter(options)
        robot = Lita::External::Robot.new
        robot.initialize_leader_lock
        p robot.send(:adapter)
        robot.run
        0
      end
    end
  end
end
