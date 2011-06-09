# method to wait until block passed returns true or timeout (default is 2 seconds) is reached 
def wait_until(timeout=2)
  time_to_stop = Time.now + timeout

  until yield 
    break if Time.now > time_to_stop
    Thread.pass
  end
end

def wait_while(timeout=2)
  time_to_stop = Time.now + timeout

  while yield 
    break if Time.now > time_to_stop
    Thread.pass
  end
end

class ::Thread
  # join with thread until given block is true, the thread joins successfully, 
  # or timeout seconds have passed
  #
  def join_until(timeout=2)
    time_to_stop = Time.now + timeout

    until yield
      break if Time.now > time_to_stop
      break if join(0.1)
    end
  end
  
  def join_while(timeout=2)
    time_to_stop = Time.now + timeout

    while yield
      break if Time.now > time_to_stop
      break if join(0.1)
    end
  end
end



