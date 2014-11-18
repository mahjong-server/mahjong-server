require 'fiddle/import'
require 'mjai/pai'
require 'mjai/player'

require 'mjai/tcp_client_game.rb'


$dllfile = "Tilt.dll"



#module mjai
module TransMaujong

	class Player < Mjai::Player
		
		module M extend Fiddle::Importer

			MJPI_INITIALIZE = 1
			MJPI_SUTEHAI = 2
			MJPI_ONACTION = 3
			MJPI_STARTGAME = 4
			MJPI_STARTKYOKU = 5
			MJPI_ENDKYOKU = 6
			MJPI_ENDGAME = 7
			MJPI_DESTROY = 8
			MJPI_YOURNAME = 9
			MJPI_CREATEINSTANCE = 10
			MJPI_BASHOGIME = 11
			MJPI_ISEXCHANGEABLE = 12
			MJPI_ONEXCHANGE = 13
			
			MJMI_GETTEHAI = 1
			MJMI_GETKAWA = 2
			MJMI_GETDORA = 3
			MJMI_GETSCORE = 4
			MJMI_GETHONBA = 5
			MJMI_GETREACHBOU = 6
			MJMI_GETRULE = 7
			MJMI_GETVERSION = 8
			MJMI_GETMACHI = 9
			MJMI_GETAGARITEN = 10
			MJMI_GETHAIREMAIN = 11
			MJMI_GETVISIBLEHAIS = 12
			MJMI_FUKIDASHI = 13
			MJMI_KKHAIABILITY = 14
			MJMI_GETWAREME = 15
			MJMI_SETSTRUCTTYPE = 16
			MJMI_SETAUTOFUKIDASHI = 17
			MJMI_LASTTSUMOGIRI = 18
			MJMI_SSPUTOABILITY = 19
			MJMI_GETYAKUHAN = 20
			MJMI_GETKYOKU = 21
			MJMI_GETKAWAEX = 22
			MJMI_ANKANABILITY = 23
			
			
			dlload $dllfile
			extern "void* MJPInterfaceFunc(void*, unsigned int, void*, void*)", :stdcall
		end
		
		def initialize(params)
			super()
			allocsize = M.MJPInterfaceFunc(nil, M::MJPI_CREATEINSTANCE, nil, nil).to_i
			@instance = Fiddle.malloc(allocsize+1000)
			
			cb = Fiddle::Closure::BlockCaller.new(Fiddle::TYPE_INT, [Fiddle::TYPE_VOIDP, -Fiddle::TYPE_INT, -Fiddle::TYPE_INT, -Fiddle::TYPE_INT]) { |inst, p1, p2, p3|
				callback(inst, p1, p2, p3)
			}
			
			if M.MJPInterfaceFunc(@instance, M::MJPI_INITIALIZE, nil, cb).to_i != 0 then
				raise "MJPI_INITIALIZE failed"
			end
			
			@struct_type = 0
		end
		
		def self.finalizer()
			M.MJPInterfaceFunc(@instance, M::MJPI_DESTROY, nil, nil)
			Fiddle.free(@instance)
		end
		
		def respond_to_action(action)
			case action.type
				when :start_game
					M.MJPInterfaceFunc(@instance, M::MJPI_STARTGAME, 0, 0)
				when :end_game
					# TODO: rank, score
					M.MJPInterfaceFunc(@instance, M::MJPI_ENDGAME, nil, nil)
				when :start_kyoku
					kyoku = (action.bakaze.data[1]-1)*4 + action.kyoku-1
					kaze = (4+self.id-action.oya.id)%4
					#M.MJPInterfaceFunc(@instance, M::MJPI_STARTKYOKU, Fiddle::Pointer[kyoku], Fiddle::Pointer[kaze])
					
					p action.oya.tehais
					raise
				when :end_kyoku
					# TODO: issue, score
					M.MJPInterfaceFunc(@instance, M::MJPI_ENDKYOKU, nil, nil)
					
					
				when :tsumo, :chi, :pon
					if action.actor == self
						return create_action({:type => :dahai, :pai => self.tehais[-1], :tsumogiri => true})
					end
			end
			
			return nil
		end
		
		def callback(inst, p1, p2, p3)
			case p1
				when M::MJMI_GETTEHAI
					raise
			end
		end
		
		def ev(str)
			p eval(str)
		end
	end
end #module TransMaujong
#end #module mjai


aa = TransMaujong::Player.new(1)
game = Mjai::TCPClientGame.new({
  :player => aa,
  :url => "mjsonp://192.168.0.1:20551/default",
  :name => "hogehoge",
})
game.play()
