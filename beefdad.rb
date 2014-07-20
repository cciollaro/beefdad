if ARGV.size < 1
	puts "try: ruby beefdad.rb <target_string>"
	exit 1
end

unless /^[0123456789abcdef]+$/ =~ ARGV.first
	puts "#{ARGV.first} is never gonna match"
	exit 1
end

require 'digest/sha1'

commit_hash = `git rev-parse HEAD`.chomp

commit_obj_info = `git cat-file -p #{commit_hash}`
commit_obj = "commit #{commit_obj_info.length}#{0.chr}#{commit_obj_info}"

puts ""
print "Searching for a timestamp so the current commit hash begins with #{ARGV.first}: "

matches = /.*\n.*(1\d{9}) ([+-]\d{4})\n.*(1\d{9}) ([+-]\d{4})/.match commit_obj

author_timestamp = matches[1].to_i
author_timestamp_location = matches.begin(1)
author_timezone = matches[2]
author_timezone_location = matches.begin(2)
committer_timestamp = matches[3].to_i
committer_timestamp_location = matches.begin(3)
committer_timezone = matches[4]
committer_timezone_location = matches.begin(4)

digest = ""
target = ARGV.first
max = 0
x = 0
author_result = ""
committer_result = ""
catch :found do
	while max < 604800 #one week
		x = 0
		while x < max
			commit_obj[author_timestamp_location, 10] = author_result = (author_timestamp - max).to_s
			commit_obj[committer_timestamp_location, 10] = committer_result = (committer_timestamp - x).to_s
			digest = Digest::SHA1.hexdigest commit_obj
			throw :found if digest[0, target.length] == target
			
			commit_obj[author_timestamp_location, 10] = author_result = (author_timestamp - x).to_s
			commit_obj[committer_timestamp_location, 10] = committer_result = (committer_timestamp - max).to_s
			digest = Digest::SHA1.hexdigest commit_obj
			throw :found if digest[0, target.length] == target
			x += 1
		end	
		commit_obj[author_timestamp_location, 10] = author_result = (author_timestamp - max).to_s
		commit_obj[committer_timestamp_location, 10] = committer_result = (committer_timestamp - max).to_s
		digest = Digest::SHA1.hexdigest commit_obj
		throw :found if digest[0, target.length] == target
		max += 1
	end
end

puts "done!"
puts ""
puts "To change the commit's hash to #{digest}, run the following command:"
puts ""
puts "\tGIT_COMMITTER_DATE=\"#{committer_result} #{committer_timezone}\" git commit --amend --no-edit --date \"#{author_result} #{author_timezone}\""
puts ""
exit 0
