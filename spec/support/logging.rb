require 'logger'

logger = Logger.new(File.expand_path('../../../test.log', __FILE__)).tap {|l| l.level = Logger::DEBUG}

# logger = Logger.new($stderr).tap { |l| l.level = Logger::DEBUG }
# Zookeeper.set_debug_level(4)

ZK.logger = logger
Zookeeper.logger = ZK.logger


def logger
  ZK.logger
end

