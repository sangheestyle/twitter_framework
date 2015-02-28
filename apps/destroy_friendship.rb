require_relative '../requests/DestroyFriendship'

require 'trollop'

$continue = true

Signal.trap(:INT) do
  $continue = false
end

USAGE = %Q{
destroy friendships: Submit a screen_name name to unfollow them/ 

Usage:
  ruby destroy_friendship.rb <options> <terms>

  terms: The name of a file containing usernames you want to unfollow, one per line.

}

def parse_command_line

  options = {type: :string, required: true}

  opts = Trollop::options do
    version "destroy_friendship 0.1 (c) 2015 Alex Tsankov"
    banner USAGE
    opt :props, "OAuth Properties File", options
  end

  unless File.exist?(opts[:props])
    Trollop::die :props, "must point to a valid oauth properties file"
  end

  opts[:terms] = ARGV[0]

  unless File.exist?(opts[:terms])
    Trollop::die "'#{opts[:terms]}' must point to a file containing screen_names terms."
  end

  opts
end

def load_terms(input_file)
  terms = []
  IO.foreach(input_file) do |term|
    terms << term.chomp
  end
  terms
end

if __FILE__ == $0

  STDOUT.sync = true

  input  = parse_command_line

  data   = { props: input[:props], terms: load_terms(input[:terms]) }

  args   = { params: {}, data: data }

  twitter = DestroyFriendship.new(args)

  #Todo: Figure out what to remove

  puts "Starting connection to Twitter's Public Streaming API."
  puts "Looking for Tweets containing the following terms:"
  puts data[:terms]

  File.open('streaming_tweets.json', 'w') do |f|
    twitter.collect do |tweet|
      f.puts "#{tweet.to_json}\n"
      puts "#{tweet["text"]}" if tweet.has_key?("text")
      if !$continue
        f.flush
        twitter.request_shutdown
      end
    end
  end

end
