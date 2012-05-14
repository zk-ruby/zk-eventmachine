gemset_name  = 'zk-em'

release_ops_path = File.expand_path('../releaseops/lib', __FILE__)

# if the special submodule is availabe, use it
# we use a submodule because it doesn't depend on anything else (*cough* bundler)
# and can be shared across projects
#
if File.exists?(release_ops_path)
  require File.join(release_ops_path, 'releaseops')
  
  # sets up the multi-ruby zk:test_all rake tasks
  ReleaseOps::TestTasks.define_for(*%w[1.8.7 1.9.2 jruby ree 1.9.3])

  # sets up the task :default => 'spec:run' and defines a simple
  # "run the specs with the current rvm profile" task
  ReleaseOps::TestTasks.define_simple_default_for_travis

  # Define a task to run code coverage tests
  ReleaseOps::TestTasks.define_simplecov_tasks

  # set up yard:server, yard:gems, and yard:clean tasks 
  # for doing documentation stuff
  ReleaseOps::YardTasks.define

  ReleaseOps::GemTasks.define('zk-eventmachine.gemspec')
end

task 'mb:test_all' => 'zk:test_all'

namespace :yard do
  task :clean do
    rm_rf '.yardoc'
  end

  task :server => :clean do
    sh "yard server --reload --port=8810"
  end

  task :gems do
    sh 'yard server --gems --port=8811'
  end
end

task :clean => 'yard:clean'


