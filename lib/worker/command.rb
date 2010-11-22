require 'rubygems'
require 'daemons'
require 'optparse'

module Worker
  class Command
    attr_accessor :worker_count
    
    def initialize(args)
      @files_to_reopen = []
      
      @worker_count = 1
      
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"
        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end

        opts.on('-n', '--number_of_workers=workers', "Number of unique workers to spawn") do |worker_count|
          @worker_count = worker_count.to_i rescue 1
        end
      end
      @args = opts.parse!(args)
    end
  
    def daemonize
      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end
      
      worker_count.times do |worker_index|
        process_name = worker_count == 1 ? "minion_worker" : "minion_worker.#{worker_index}"
        Daemons.run_proc(process_name, :dir => "#{RAILS_ROOT}/tmp/pids", :dir_mode => :normal, :ARGV => @args) do |*args|
          run process_name
        end
      end
    end
    
    def run(worker_name = nil)
      Dir.chdir(RAILS_ROOT)
      
      # Re-open file handles
      @files_to_reopen.each do |file|
        begin
          file.reopen File.join(RAILS_ROOT, 'log', 'workers.log'), 'a+'
          file.sync = true
        rescue ::Exception
        end
      end
      
      ActiveRecord::Base.connection.reconnect!
      
      worker = Worker::LinuxWorker.new(Rails.logger)
      worker.start
    rescue => e
      Rails.logger.fatal e
      STDERR.puts e.message
      exit 1
    end
    
  end
end
