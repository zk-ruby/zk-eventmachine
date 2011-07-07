## ZKEventMachine

ZKEventMachine is a [ZK][] client implementation for [EventMachine][] for interacting with the Apache [ZooKeeper][] server. It provides the core functionality of [ZK][], but in a single-threaded context with a callback-based API. It is tested on [JRuby][], and [MRI][] versions 1.8.7 and 1.9.2. [Rubinius][] 1.2.x _should_ work, but support should be considered experimental at this point (if you find a bug, please [report it][], and I'll do my best to fix it).

### Quickstart

Installation via rubygems is recommended, as there are a few dependencies. 

    $ gem install zk-eventmachine

This will install [ZK][] and [slyphon-zookeeper][] _(as a side note, for experimentation in irb, it's probably easier to use [ZK][] due to its synchronous nature)_. 

### Connecting

Connections are easy to set up, and take the same host string argument that the ZK and Zookeeper use. 

    # a connection to a single server:

    zkem = ZK::ZKEventMachine::Client.new("localhost:2181")

    zkem.connect do
      # the client is connected when this block is called
    end

_Note: at the moment, the [chroot-style][] syntax is iffy and needs some attention._

Closing a connection should be done in the same style, by passing a block to the _close_ method.

    zkem.close do
      # connection is closed when this block is called
    end

Due to the way that the underlying [slyphon-zookeeper][] code is written, it is important that you not stop the reactor until the `on_close` callback has fired (especially when using `epoll` on linux). Strange things may happen if you do not wait for the connection to be closed!


### Callbacks

ZKEventMachine was written so that every call can handle two callback styles. The first is node-js style:

    zkem.get('/') do |exception,value,stat|
    end

In this style, the first value returned to the block is an Exception object if an error occured, or nil if the operation was successful. The rest of the arguments are the same as they would be returned from the synchronous API.

The second style uses EventMachine::Deferrable (with a few slight modifications), and allows you to add callbacks and errbacks (in something approximating Twisted Python style).

    d = zkem.get('/')

    d.callback do |value,stat|
      # success
    end

    d.errback do |exc|
      # failure
    end

The callback/errbacks return self, so you can chain calls:

    zkem.get('/').callback do |value,stat|

    end.errback do |exc|

    end

Also provided is an `ensure_that` method that will add the given block to both callback and errback chains:

    # the goalposts |*| below are so that the block can take any number of
    # args, and ignore them

    zkem.get('/').ensure_that do |*|
      # clean up 
    end

### Example Usage

### Contributing

### Credits

ZKEventMachine is developed and maintained by Jonathan Simms and Topper Bowers. The HP Development Corp. has graciously open sourced this project under the MIT License, and special thanks go to [Snapfish][] who allowed us to develop this project. 

[ZK]: https://github.com/slyphon/zk
[EventMachine]: https://github.com/eventmachine/eventmachine
[ZooKeeper]: http://zookeeper.apache.org/
[slyphon-zookeeper]: https://github.com/slyphon/zookeeper
[JRuby]: http://jruby.org
[MRI]: http://www.ruby-lang.org/
[Rubinius]: http://rubini.us
[report it]: https://github.com/slyphon/zk-eventmachine/issues
[chroot-style]: http://zookeeper.apache.org/doc/r3.2.2/zookeeperProgrammers.html#ch_zkSessions
[Snapfish]: http://www.snapfish.com

