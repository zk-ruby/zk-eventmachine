guard 'bundler' do
  watch 'Gemfile'
  watch /\A.+\.gemspec\Z/
end

guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})

  watch(%r{^lib/(.+)\.rb$}) do |m| 
    generic = "spec/#{m[1]}_spec.rb"

    if test(?f, generic)
      generic
    else
      'spec'
    end
  end

  watch(%r%^spec/(spec_helper.rb|support|shared)(?:$|/)%)  { "spec" }

end

