require ('json')
require ('pp')

require ('./match.rb')
require ('./player.rb')

Beta = (25.0 / 6) ** 2
Kappa = 0.0001
Gamma = 0.1

def update_bayesian_rating(players, match)
  return unless match.valid?

  players_in_match = []
  match.players.each do |player_name|
    players_in_match << players[player_name]
  end

  deltas = {}
  etas = {}

  players_in_match.permutation(2) do |p1, p2|
    p1_name = p1.name
    p2_name = p2.name
    m_1 = p1.bayesian_mean
    m_2 = p2.bayesian_mean
    v_1 = p1.bayesian_variance
    v_2 = p2.bayesian_variance
    r_1 = match.rank(p1_name) # player 1's rank (the lesser the better)
    r_2 = match.rank(p2_name)

    c_iq = (v_1 + v_2 + 2 * Beta**2) ** 0.5
    p_iq = Math.exp(m_1/c_iq) / (Math.exp(m_1/c_iq) + Math.exp(m_2/c_iq))

    s = (r_1 < r_2) ? 1 : 0 # s becomes 0 if player 1 was superior to player 2

    deltas[p1_name] = 0 unless deltas[p1_name]
    etas[p1_name] = 0 unless etas[p1_name]

    gamma = v_1 ** 0.5 / c_iq

    deltas[p1_name] += v_1 / c_iq * (s - p_iq)
    etas[p1_name] = gamma * v_1 / (c_iq ** 2) * p_iq * (1 - p_iq)
  end

  players_in_match.each do |player|
    delta_mean = deltas[player.name]
    delta_variance = [1 - etas[player.name], Kappa].max

    player.update_bayesian_rating(delta_mean, delta_variance)
  end
end


def update_rating(players, match)
  return unless match.valid?

  players_in_match = []

  match.players.each do |player_name|
    players_in_match << players[player_name]
  end

  r_sum = players_in_match.inject(0.0) {|r_sum_so_far, player| r_sum_so_far + player.rating}
  r_ave = r_sum / players_in_match.size

  players_in_match.each do |player|
    rank = match.ranks[player.name] + 1
    r  = player.rating
    r_delta = (50 - rank * 20 + (r_ave - r) / 40.0) * 0.2

    player.update_rating(r_delta)
  end
end

if __FILE__ == $0 then

  # open match data to be applied
  matches_in_json = open(ARGV[0]) {|io| JSON.load(io)}

  matches = []
  matches_in_json.each {|id, attr| matches << Match.new(id, attr)}

  # open player data
  players_in_json = open(ARGV[1]) {|io| JSON.load(io)} if File.file?(ARGV[1])

  players = {}
  players_in_json.each {|name, attr| players[name] = Player.new(name, attr)}

  matches.each do |match|
    update_rating(players, match)
    update_bayesian_rating(players, match)
  end

  open(ARGV[1], 'w') do |io|
    json = JSON.pretty_generate(Player.to_hash(players.values))
    io.puts json
  end
end
