require 'json'
require 'pp'

def update_rating(players, match)
  return unless match["scores"]

  players_in_match = {}

  # assume match["players"] is an array of each player's name
  match["players"].each do |name|
    players_in_match[name] = players[name]
  end

  r_sum = 0
  players_in_match.each do |name, dat|
    r_sum + dat["rating"]
  end

  r_ave = r_sum / 4.0

  players_in_match.each do |name, dat|
    rank = match["rank"][name] + 1
    r  = dat["rating"]
    r_ = r + (50 - rank * 20 + (r_ave - r) / 40.0) * 0.2

    dat["rating"] = r_
  end
end

if __FILE__ == $0 then

  # open match data to be applied
  matches = open(ARGV[0]) {|io| JSON.load(io)}
  # open player data
  players = open(ARGV[1]) {|io| JSON.load(io)} if File.file?(ARGV[1])

  matches.each do |_, match|
    update_rating(players, match)
  end

  open(ARGV[1], 'w') do |io|
    json = JSON.pretty_generate(players)
    io.puts json
  end
end
