require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :rackup, :repository_path  do |t, args|
  require "rack"
  require "rack/git"

  repository_path = args[:repository_path] || "spec/fixtures/default/dotgit"
  app = Rack::Lint.new(Rack::Git::File.new(File.expand_path(repository_path)))

  Rack::Server.new(app: app).start
end
