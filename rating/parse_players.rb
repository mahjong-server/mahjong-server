require 'json'
require 'pp'
require 'set'

require ('./match.rb')
require ('./player.rb')

# Returns an enumerable of players that played in the given matches.
# No duplicate elements are stored in the return value
def find_players(matches)
  players = Set.new

  matches.each do |match|
    match.players.each {|p| players << p}
  end

  players
end

if __FILE__ == $0 then

  # open match data to be applied
  matches_in_json = open(ARGV[0]) {|io| JSON.load(io)}

  matches = []
  matches_in_json.each {|id, attr| matches << Match.new(id, attr)}

  players = []

  # open player data
  if File.file?(ARGV[1]) then
    players_in_json = open(ARGV[1]) {|io| JSON.load(io)}

    players_in_json.each {|id, attr| players << Player.new(id, attr)}
  end

  # this is an array of player names
  players_in_the_game = find_players(matches)

  players_in_the_game.each do |player_name|
    unless players.any? {|player| player.name == player_name} then
      players << Player.new(player_name)
    end
  end

  open(ARGV[1], 'w') do |io|
    json = JSON.pretty_generate(Player.to_hash(players))
    io.puts json
  end
end
