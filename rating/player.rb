module RRating

  attr_accessor :rating

  def initialize
    self.rating = 1500
  end

  def update(r_delta)
    rating += r_delta
  end

  def to_hash
    {rating: rating}
  end
end

module BayesRating

  Beta = (25.0 / 6) ** 2
  Kappa = 0.0001
  Gamma = 0.1

  attr_accessor :mean, :variance

  def initalize
    self.mean = 0.0
    self.variance = 1.0
  end
end

class Player

  attr_accessor :name, :attributes

  def initialize(name, attributes = {})
    self.name = name

    if attributes.empty? then
      self.attributes = {"rating" => 1500, "mean" => 0.0 , "variance" => 1.0}
    else
      self.attributes = attributes
    end
  end

  def rating
    attributes["rating"]
  end

  def update_rating(r_delta)
    attributes["rating"] += r_delta
  end

  def bayesian_mean
    attributes["mean"]
  end

  def bayesian_variance
    attributes["variance"]
  end

  def update_bayesian_rating(delta_mean, delta_variance)
    attributes["mean"] += delta_mean
    attributes["variance"] *= delta_variance
  end

  def self.to_hash(players)
    hash = {}

    players.each do |player|
      hash[player.name] = player.attributes
    end

    hash
  end

end

