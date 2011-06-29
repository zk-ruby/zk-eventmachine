require 'logger'

# logger = Logger.new(File.expand_path('../../../test.log', __FILE__)).tap {|l| l.level = Logger::DEBUG}

logger = Logger.new($stderr).tap { |l| l.level = Logger::DEBUG }

ZK.logger = logger
Zookeeper.logger = ZK.logger

Zookeeper.set_debug_level(4)

def logger
  ZK.logger
end

