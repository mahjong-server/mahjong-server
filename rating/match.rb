require ('json')

# A class representing a match
class Match

  attr_accessor :id

  def initialize(id, attributes = {})
    @id = id
    @attributes = attributes
  end

  def valid?
    ["scores", "ranks", "players"].all? {|key| @attributes.has_key?(key)}
  end

  def scores
    @attributes["scores"]
  end

  def ranks
    @attributes["ranks"]
  end

  def rank(player_name)
    ranks[player_name]
  end

  def players
    @attributes["players"]
  end
end
