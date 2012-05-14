require 'logger'

log_file = File.open(File.expand_path('../../../test.log', __FILE__), 'a').tap { |f| f.sync = true }

Logger.new(log_file).tap do |log| 
  log.level = Logger::DEBUG 
  ZK.logger = log
#   Zookeeper.logger = log
end

# for debugging along with C output uncomment the following
#
# $stderr.sync = true
# logger = Logger.new($stderr).tap { |l| l.level = Logger::DEBUG }
# Zookeeper.set_debug_level(4)

module SpecGlobalLogger
  def logger
    ZK.logger
  end

  # sets the log level to FATAL for the duration of the block
  def mute_logger
    orig_level, ZK.logger.level = ZK.logger.level, Logger::FATAL
    orig_zk_level, Zookeeper.debug_level = Zookeeper.debug_level, Zookeeper::Constants::ZOO_LOG_LEVEL_ERROR
    yield
  ensure
    ZK.logger.level = orig_level
  end
end


