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

START_MINUTE_MULT = 5
GUARD_INTERVAL_SEC = 60

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

def play_game(clients)
	
	game = nil
	date_string = Time.now.strftime("%Y-%m-%d-%H%M%S")
	
	mjson_path = "mjlog/%s.mjson" % date_string
	log_path = "srvlog/%s.txt" % date_string
	
	log_out = open(log_path, "w")
	log_out.printf(date_string + "\n")
	
	players = []
	clients.each do |c|
		players.push(Mjai::TCPPlayer.new(c.socket, c.screen_name, log_out))
		log_out.printf("%s: %s\n", c.screen_name, c.socket.peeraddr.to_s);
	end
	STDERR.puts "Game start: " + clients.collect{|c| [c.socket.peeraddr.to_s, c.screen_name]}.to_s
	Thread.current[:gameid] = date_string
	
	begin
		mjson_out = open(mjson_path, "w")
		if mjson_out then
			mjson_out.sync = true
		end
		
		game = Mjai::ActiveGame.new(players)
		game.game_type = :tonpu
		game.on_action() do |action|
			game.dump_action(action, log_out)
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
		
		log_out.printf("finished " + Time.now.strftime("%Y-%m-%d-%H%M%S") + "\n")
		
		mjson_out.close if mjson_out
		
	rescue Mjai::GameFailError
	
		# error log
		mjstat = open("mjlog/stat.txt", "a")
		mjstat.puts( JSON.dump({"type" => "error", "idtime" => date_string, "time" => Time.now.strftime("%Y-%m-%d-%H%M%S") , "criminal" => $!.player, "message" => $!.message.to_s}) )
		mjstat.close
		
		log_out.printf("GameFailError " + $!.player.to_s + " " + Time.now.strftime("%Y-%m-%d-%H%M%S") + " " + $!.message.to_s + "\n")
		
		STDERR.puts ("player " + $!.player.to_s + " " + $!.response.to_s)
		print_backtrace($!, log_out)
	rescue
		# error log
		mjstat = open("mjlog/stat.txt", "a")
		mjstat.puts( JSON.dump({"type" => "error", "idtime" => date_string, "time" => Time.now.strftime("%Y-%m-%d-%H%M%S") , "criminal" => -1, "message" => $!.message.to_s}) )
		mjstat.close
		
		log_out.printf("Other Error " + Time.now.strftime("%Y-%m-%d-%H%M%S") + "\n")
		STDERR.puts ("Other Error")
		print_backtrace($!, log_out)
		print_backtrace($!)
	end
	
	Mjai::FileConverter.new().convert(mjson_path, "#{mjson_path}.html") if mjson_path
	
	begin
		players.each do |p|
			p.close
		end
	rescue
	end
	
	log_out.close
	
	return [game, success]
end



final_game_started = -1

while true
	socks = clients.collect{|c| c.socket}
	socks.push(server)
	
	ready = select(socks, [], [], 5)
	if ready != nil then
		
		ready[0].each do |socket|
			
			if socket == server then
				# accept
				cl = server.accept
				
				begin
					cl.sync = true
					cl.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
					STDERR.puts "Accepted " + cl.peeraddr.to_s
					cl.puts(JSON.dump({"type" => "hello", "protocol" => "mjsonp", "protocol_version" => 1}))
					
					clients.push( Client.new(cl, nil, ClientStatus::ACCEPTED) )
				rescue
					cl.close
				end
			else
				clnum = clients.index{|c| c.socket == socket}
				begin
					line = socket.gets
				rescue
					line = ""
				end
				
				if !line then
					addr = "unknown"
					begin
						addr = socket.peeraddr.to_s
					rescue
					end
					
					STDERR.puts "Disconnected " + addr
					clients.delete_at(clnum)
					socket.close
					next
				end
				
				p line
				
				if clients[clnum].status == ClientStatus::ACCEPTED then
					begin
						message = JSON.parse(line)
						if message["type"] != "join" || !message["name"] then
							raise
						end
						
						clients[clnum].screen_name = message["name"].encode("UTF-16BE", "UTF-8", :invalid => :replace, :undef => :replace, :replace => '?').encode("UTF-8")
					
					rescue
						addr = "unknown"
						begin
							socket.puts(JSON.dump({"type" => "error", "message" => "invalid join"}))
							addr = socket.peeraddr.to_s
						rescue
						end
						
						STDERR.puts ("Invalid join " + addr)
						socket.close
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
	
	
	n = Time.now
	if n.min % START_MINUTE_MULT == 0 && (n.to_i - final_game_started)>GUARD_INTERVAL_SEC then
		
		final_game_started = n.to_i
		
		
		loop do
			
			# クライアントが4人揃っていたらスタート
			readycl = clients.find_all{|c| c.status == ClientStatus::READY}
			if readycl.count < 4 then
				break
			end
			
			STDERR.puts "starting game..."
			
			# 4人選び出す
			playcl = readycl.sample(4)
			
			# 開始クライアントは削除
			clients = clients - playcl
			
			Thread.new(playcl) do |cls|
				play_game(cls)
			end
			
			sleep(1)
			
		end
	end
	
	table_str = clients.find_all{|c| c.status == ClientStatus::READY}.count.to_s + ":" +
		((Thread::list.find_all{|t| t[:gameid]}.count)*4).to_s
	
	# https://docs.ruby-lang.org/ja/latest/method/File/i/flock.html
	File.open("mjlog/table.txt", File::RDWR|File::CREAT, 0644) {|f|
		f.flock(File::LOCK_EX)
		f.rewind
		f.write(table_str)
		f.flush
		f.truncate(f.pos)
	}
	
end

