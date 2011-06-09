require 'logger'

ZK.logger = Logger.new(File.expand_path('../../../test.log', __FILE__)).tap {|l| l.level = Logger::DEBUG}

def logger
  ZK.logger
end

