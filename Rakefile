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

gemset_name  = 'zk-em'

%w[1.8.7 1.9.2 jruby rbx 1.9.3].each do |ns_name|
  rvm_ruby = (ns_name == 'rbx') ? "rbx-2.0.testing" : ns_name

  ruby_with_gemset        = "#{rvm_ruby}@#{gemset_name}"
  create_gemset_task_name = "mb:#{ns_name}:create_gemset"
  bundle_task_name        = "mb:#{ns_name}:bundle_install"
  rspec_task_name         = "mb:#{ns_name}:run_rspec"

  phony_gemfile_link_name = "Gemfile.#{ns_name}"
  phony_gemfile_lock_name = "#{phony_gemfile_link_name}.lock"

  file phony_gemfile_link_name do
    # apparently, rake doesn't deal with symlinks intelligently :P
    ln_s('Gemfile', phony_gemfile_link_name) unless File.symlink?(phony_gemfile_link_name)
  end

  task :clean do
    rm_rf [phony_gemfile_lock_name, phony_gemfile_lock_name]
  end

  task create_gemset_task_name do
    sh "rvm #{rvm_ruby} do rvm gemset create #{gemset_name}" 
  end

  task bundle_task_name => [phony_gemfile_link_name, create_gemset_task_name] do
    sh "rvm #{ruby_with_gemset} do bundle install --gemfile #{phony_gemfile_link_name}"
  end

  task rspec_task_name => bundle_task_name do
    sh "rvm #{ruby_with_gemset} do env BUNDLE_GEMFILE=#{phony_gemfile_link_name} bundle exec rspec spec --fail-fast"
  end

  task "mb:#{ns_name}" => rspec_task_name

  task "mb:test_all_rubies" => rspec_task_name
end

task 'mb:test_all' do
  require 'benchmark'
  tm = Benchmark.realtime do
    Rake::Task['mb:test_all_rubies'].invoke
  end

  $stderr.puts "Test run took: #{tm}"
end

