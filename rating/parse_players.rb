require 'json'
require 'pp'
require 'set'

def find_players(matches)
  players = Set.new()

  matches.each do |_, match|
    match["players"].each {|p| players << p}
  end
  players
end

def make_player(name)
  {"rating" => 1500}
end

if __FILE__ == $0 then
  players = {}

  # open match data to be applied
  matches = open(ARGV[0]) {|io| JSON.load(io)}
  # open player data
  players = open(ARGV[1]) {|io| JSON.load(io)} if File.file?(ARGV[1])

  new_players = find_players(matches)

  new_players.each do |new_player|
    unless players[new_player] then
      players[new_player] = make_player(new_player)
    end
  end

  open(ARGV[1], 'w') do |io|
    json = JSON.pretty_generate(players)
    io.puts json
  end
end
