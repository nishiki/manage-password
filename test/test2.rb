require 'open3'

Open3.popen3("./bin/mpw config --init test@test.com") do |stdin, stdout, stderr, thread|
	stdin.puts 'test'
	stdin.puts 'test'
end

Open3.popen3("./bin/mpw list") do |stdin, stdout, stderr, thread|
	stdin.puts 'test'
	puts stdout
end
