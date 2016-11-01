require "websocket-client-simple"

require "rubygems"
require "json"

require "mjai/game"
require "mjai/action"
require "mjai/puppet_player"


module Mjai
  
  class WSClientGame < Game
    
    def initialize(params)
      super()
      @params = params
    end
    
    def play()
      ws = WebSocket::Client::Simple.connect @params[:url]
      wsout, wsin = IO.pipe

      ws.on :message do |msg|
        wsin.puts msg
      end

      ws.on :close do |e|
        p e
        exit 1
      end
      
      wsout.each_line() do |line|
        puts("<-\t%s" % line.chomp())
        action_json = line.chomp()
        action_obj = JSON.parse(action_json)
        case action_obj["type"]
        when "hello"
          response_json = JSON.dump({
                                      "type" => "join",
                                      "name" => @params[:name],
                                      "room" => "default",
                                    })
        when "error"
          break
        else
          if action_obj["type"] == "start_game"
            @my_id = action_obj["id"]
            self.players = Array.new(4) do |i|
              i == @my_id ? @params[:player] : PuppetPlayer.new(i)
            end
          end
          action = Action.from_json(action_json, self)
          
          begin
            responses = do_action(action)
            break if action.type == :end_game
            response = responses && responses[@my_id]
          rescue GameFailError
            response = {
              :type => :error,
              :actor => @my_id,
              :message => "%s - Original Action: %s, My Response: %s" % [$!.message, $!.orig_action.to_s, $!.response.to_s]
            }
          rescue
            ex = $!
            mess = ("%s: %s (%p)\n" % [ex.backtrace[0], ex.message, ex.class])
            for s in ex.backtrace[1..-1]
              mess += ("        %s\n" % s)
            end
            response = {
              :type => :error,
              :actor => @my_id,
              :message => ex.message,
              :log => mess
            }
          end
          
          response_json = response ? response.to_json() : JSON.dump({"type" => "none"})
        end
        puts("->\t%s" % response_json)
        ws.send response_json
      end
    end
    
    def expect_response_from?(player)
      return player.id == @my_id
    end
    
  end
  
end
