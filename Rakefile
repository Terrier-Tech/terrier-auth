require "bundler/gem_tasks"
require "rake/testtask"

# Require the main entry file of the gem
require_relative 'lib/terrier_auth'

# Automatically require all .rake files in lib/tasks
Dir.glob('lib/tasks/**/*.rake').each { |rake_file| load rake_file }

# set up tests
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
