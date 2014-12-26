require 'mjai/tcp_client_game.rb'

require './wrapper_player.rb'

player = TransMaujong::WrapperPlayer.new

game = Mjai::TCPClientGame.new({
  :player => player,
  :url    => "mjsonp://localhost:/default",
  :name   => player.name
})

game.play()
