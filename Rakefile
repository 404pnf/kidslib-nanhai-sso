desc "help msg"
task :help do
  system('rake -T')
end

desc "run the app"
task :run do
  system("rackup")
end

desc "genreate docs"
task :doc do
  system("docco *.rb")
end

desc "show stats of line of code "
task :loc do
  system("cloc *.rb")
end

desc "run robocop"
task :cop do
  system("rubocop *.rb")
end

desc "run test"
task :test do
  system("ruby test/*.rb")
end

task :default => [:test]
