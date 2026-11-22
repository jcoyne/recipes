require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
end

# The front end's grocery list parser (site/grocery.js) is tested with Node's built-in runner.
desc 'Run the JavaScript tests'
task 'test:js' do
  sh 'node', '--test', *Dir.glob('test/**/*.test.mjs')
end
task test: 'test:js'

task default: :test

Dir.glob(File.expand_path('lib/tasks/*.rake', __dir__)).each { |file| load file }
