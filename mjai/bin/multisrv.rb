#!/usr/bin/ruby

require "rubygems"
require "bundler/setup"

require "socket"
require "thread"

require "mjai/tcp_player"
require "mjai/active_game"
require "mjai/file_converter"

SERVER_HOST = "0.0.0.0"
SERVER_PORT = 11600

module ClientStatus
  ACCEPTED = 1
  READY = 2
#  WAIT_PING = 3
end

Client = Struct.new("Client", :socket, :screen_name, :status)
clients = []

server = TCPServer.open(SERVER_HOST, SERVER_PORT)

def print_backtrace(ex, io = $stderr)
	io.printf("%s: %s (%p)\n", ex.backtrace[0], ex.message, ex.class)
	for s in ex.backtrace[1..-1]
		io.printf("        %s\n", s)
	end
end

def play_game(players)
	
	game = nil
	date_string = Time.now.strftime("%Y-%m-%d-%H%M%S")
	
	
	begin
		mjson_path = "mjlog/%s.mjson" % date_string
		
		mjson_out = open(mjson_path, "w")
		if mjson_out then
			mjson_out.sync = true
		end
		
		game = Mjai::ActiveGame.new(players)
		game.game_type = :tonpu
		game.on_action() do |action|
			game.dump_action(action, STDERR)
		end
		game.on_responses() do |action, responses|
			mjson_out.puts(action.to_json()) if mjson_out
		end
		
		# start log
		mjstat = open("mjlog/stat.txt", "a")
		mjstat.puts( JSON.dump({"type" => "start", "idtime" => date_string, "player" => game.players.collect{|p| p.name} }) )
		mjstat.close
		
		score = game.play()
		
		# end log
		mjstat = open("mjlog/stat.txt", "a")
		mjstat.puts( JSON.dump({"type" => "finish", "idtime" => date_string, "time" => Time.now.strftime("%Y-%m-%d-%H%M%S") , "score" => score}) )
		mjstat.close
		
		mjson_out.close if mjson_out
		
		Mjai::FileConverter.new().convert(mjson_path, "#{mjson_path}.html") if mjson_path
		
	rescue Mjai::GameFailError
	
		# error log
		mjstat = open("mjlog/stat.txt", "a")
		mjstat.puts( JSON.dump({"type" => "error", "idtime" => date_string, "time" => Time.now.strftime("%Y-%m-%d-%H%M%S") , "criminal" => $!.player, "message" => $!.message.to_s}) )
		mjstat.close
		
		print_backtrace($!)
		STDERR.puts ("player " + $!.player.to_s + " " + $!.response)
	rescue
		# error log
		mjstat = open("mjlog/stat.txt", "a")
		mjstat.puts( JSON.dump({"type" => "error", "idtime" => date_string, "time" => Time.now.strftime("%Y-%m-%d-%H%M%S") , "criminal" => -1, "message" => $!.message.to_s}) )
		mjstat.close
		
		STDERR.puts ("Other Error")
		print_backtrace($!)
	end
	
	begin
		players.each do |p|
			p.close
		end
	rescue
	end
	
	return [game, success]
end



while true
	socks = clients.collect{|c| c.socket}
	socks.push(server)
	
	ready = select(socks, [], [], 10)
	if ready != nil then
		
		ready[0].each do |socket|
			
			if socket == server then
				# accept
				cl = server.accept
				cl.sync = true
				cl.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
				clients.push( Client.new(cl, nil, ClientStatus::ACCEPTED) )
				STDERR.puts "Accepted " + cl.peeraddr.to_s
				
				cl.puts(JSON.dump({"type" => "hello", "protocol" => "mjsonp", "protocol_version" => 1}))
			else
				line = socket.gets
				clnum = clients.index{|c| c.socket == socket}
				
				if !line then
					STDERR.puts "Disconnected " + socket.peeraddr.to_s
					clients.delete_at(clnum)
					socket.close
					next
				end
				
				if clients[clnum].status == ClientStatus::ACCEPTED then
					begin
						message = JSON.parse(line)
						if message["type"] != "join" || !message["name"] then
							raise
						end
						
						clients[clnum].screen_name = URI.encode(message["name"])
					
					rescue
						begin
							socket.puts(JSON.dump({"type" => "error", "message" => "invalid join"}))
							socket.close
						rescue
						end
						
						STDERR.puts ("Invalid join " + socket.peeraddr.to_s)
						clients.delete_at(clnum)
						next
					end
					
					# join成功
					clients[clnum].status = ClientStatus::READY
					STDERR.puts "Joined " + clients[clnum].screen_name + " " + socket.peeraddr.to_s
				end
			end
		end
	end
	
	
	# クライアントが4人揃っていたらスタート
	readycl = clients.find_all{|c| c.status == ClientStatus::READY}
	if readycl.count < 4 then
		next
	end
	
	STDERR.puts "starting game..."
	
	# 4人選び出す
	playcl = readycl.sample(4)
	
	# 開始クライアントは削除
	clients = clients - playcl
	
	players = []
	playcl.each do |c|
		players.push(Mjai::TCPPlayer.new(c.socket, c.screen_name))
	end
	
	Thread.new(players) do |p|
		play_game(p)
	end
	
end

