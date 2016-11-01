$:.unshift File.dirname(__FILE__)

require 'mjai/ws_client_game.rb'

$dllname = "MaujongPlugin/%s.dll" % ARGV[0]
if ( ARGV[0].include?("/") || ARGV[0].include?("\\") ) then
  $dllname = $ARGV[0]
end

require 'wrapper_player.rb'

player = TransMaujong::WrapperPlayer.new

game = Mjai::WSClientGame.new({
  :player => player,
  :url    => "ws://www.logos.t.u-tokyo.ac.jp/mjai/",
  :name   => player.name
#  :name   => "Akagi"
})

game.play()
