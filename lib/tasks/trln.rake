require 'yaml'
require 'traject/command_line'

# Usage: rake trln:index testData/DCrecds10.mrc

config = YAML.load(
		File.read(
			File.join(Rails.root, "config/trln.yml")
		)
	)[Rails.env].deep_symbolize_keys()

desc "Custom tasks for TRLN"
namespace :trln do
		desc 'Indexes supplied files.  See config/index.yml'
    task :index do
			# todo : put this into a library
			configfiles = config[:traject][:config_files].collect {
				|f|
				[ '-c', File.absolute_path(f,File.join(Rails.root, 'config/traject')) ]
			}.flatten!
			
			args = config[:traject][:cmdline_base]
			args <<= configfiles
			# now stick on all the files specified after
			# the task name
			args = (args << ARGV[1..-1]).flatten!
			cmdline = Traject::CommandLine.new(args)
			result = cmdline.execute
			if result
        puts "Mapping complete."
			else
				exit 1
			end
		end
end