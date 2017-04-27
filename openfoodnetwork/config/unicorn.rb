app_path = File.expand_path(File.dirname(__FILE__) + '/..')

# amount of unicorn workers to spin up
worker_processes (ENV['RAILS_ENV'] == 'production' ? 2 : 1)

# restarts workers that hang for 30 seconds
timeout 120

listen app_path + '/tmp/unicorn.sock', backlog: 64

listen(3000, backlog: 64) if ENV['RAILS_ENV'] == 'development'

# Set the working directory of this unicorn instance.
working_directory app_path

pid app_path + '/tmp/unicorn.pid'

preload_app true

# Garbage collection settings.
GC.respond_to?(:copy_on_write_friendly=) &&
  GC.copy_on_write_friendly = true

# If using ActiveRecord, disconnect (from the database) before forking.
before_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

# After forking, restore your ActiveRecord connection.
after_fork do |server, worker|
  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end