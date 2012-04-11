require 'bundler'
Bundler::GemHelper.install_tasks

task :yard do
  Bundler.setup
  require 'yard'

  YARD::Rake::YardocTask.new(:run_yardoc) do |t|
    t.files = ['lib/**/*.rb']
  end

  Rake::Task[:run_yardoc].invoke
end

%w[1.8.7 1.9.2 1.9.3 jruby].each do |rvm_ruby|
  gemset_name         = 'zk-em'
  ruby_with_gemset    = "#{rvm_ruby}@#{gemset_name}"
  create_gemset_name  = "mb:#{rvm_ruby}:create_gemset"
  bundle_task_name    = "mb:#{rvm_ruby}:bundle_install"
  rspec_task_name     = "mb:#{rvm_ruby}:run_rspec"

  task create_gemset_name do
    sh "rvm #{rvm_ruby} do rvm gemset create #{gemset_name}" 
  end

  task bundle_task_name => create_gemset_name do
    rm_f 'Gemfile.lock'
    sh "rvm #{ruby_with_gemset} do bundle install"
  end

  task rspec_task_name => bundle_task_name do
    sh "rvm #{ruby_with_gemset} do bundle exec rspec spec"
  end

  task 'mb:test_all' => rspec_task_name
end

