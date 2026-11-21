require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

task default: :test

Dir.glob(File.expand_path('lib/tasks/*.rake', __dir__)).each { |file| load file }
