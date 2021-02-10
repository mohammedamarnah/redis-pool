require 'rubocop/rake_task'
require 'rake/testtask'

task default: %w[lint test]

RuboCop::RakeTask.new(:lint) do |task|
  task.patterns = ['lib/**/*.rb', 'test/**/*.rb']
  task.fail_on_error = false
end

Rake::TestTask.new do |task|
  task.test_files = FileList['test/**/*.rb']
end

