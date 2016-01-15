require 'json'

players = []
matches = []

while line = gets do
  json = JSON.parse(line)

  if json["type"] == "start" then
    throw "duplicate matches" if matches.find {|match| match[:idtime] == json["idtime"]}

    players_in_match = []
    json["player"].each do |name|
      unless players.find {|player| player[:name] == name} then
        players << {:name => name, :rating => 1500}
      end

      players_in_match << name
    end

    matches << {:idtime => json["idtime"], :players => players_in_match}
  elsif json["type"] == "finish" then
    matches.find {|match| match[:idtime] == json["idtime"]}[:score] = json["score"] 
  end
end

matches.each do |match|
  next unless match[:score]

  sum_r = 0
  match[:players].each do |player|
    sum_r += players.find {|p| p[:name] == player}[:rating]
  end

  scores_in_match = []
  match[:score].each_with_index do |score, i|
    scores_in_match << {:score => score, :index => i}
  end

  scores_in_match.sort_by {|e| e[:score]}

  scores_in_match.each_with_index do |res, rank|
    p = players.find {|p| p[:name] == match[:players][res[:index]]} 
    p[:rating] += (50 - (rank + 1) * 20 + (sum_r / 4.0 - p[:rating]) / 40.0) * 0.2
  end
end

puts players.sort_by {|e| e[:rating] }
