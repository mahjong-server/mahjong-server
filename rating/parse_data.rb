#!/usr/bin/env ruby

require 'json'
require 'pp'

def rank(players, scores)
  sorted_players = scores.zip(players).sort.reverse.transpose[1]

  result = {}
  sorted_players.each_with_index do |players, rank|
    result[players] = rank
  end

  result
end

def insert(line, matches)
  json = JSON.parse(line)

  if json["type"] == "start" then
    throw "duplicate matches found" if matches[json["idtime"]]

    matches[json["idtime"]] = {players: json["player"]}
  elsif json["type"] == "finish" then
    match = matches[json["idtime"]]

    match[:scores] = json["score"]
    match[:ranks] = rank(match[:players], match[:scores])
  end
end

if __FILE__ == $0 then

  # idtime => match
  matches = {}

  while line = gets do
    insert(line, matches)
  end

  puts JSON.pretty_generate(matches)
end

