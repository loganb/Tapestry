require 'rdoc/task'

Rake::RDocTask.new do |rdoc|
  version = Tapestry::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tapestry #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end