require "timeout"

require "mjai/player"
require "mjai/action"
require "mjai/validation_error"


module Mjai
    
    class TCPPlayer < Player
        
        TIMEOUT_SEC = 600
        
        def initialize(socket, name)
          super()
          @socket = socket
          @closed = false
          self.name = name
        end
        
        def respond_to_action(action)
          
          begin
            
            if @closed then
                return Action.new({:type => :none})
            end
            
            puts("server -> player %d\t%s" % [self.id, action.to_json()])
            
            begin
                @socket.puts(action.to_json())
            rescue
                @closed = true
                return create_action({:type => :error, :message => "(puts) disconnected"})
            end
            
            if action.type == :error then
                close()
            else
                line = nil
                begin
                    Timeout.timeout(TIMEOUT_SEC) do
                      line = @socket.gets()
                    end
                rescue
                end
                
                if line
                  puts("server <- player %d\t%s" % [self.id, line])
                  return Action.from_json(line.chomp(), self.game)
                else
                  puts("server :  Player %d has disconnected." % self.id)
                  @closed = true
                  
                  if action.type == :end_game then
                      return Action.new({:type => :none})
                  end
                  return create_action({:type => :error, :message => "(gets) disconnected"})
                end
            end
            
          rescue Timeout::Error
            return create_action({
                :type => :error,
                :message => "Timeout. No response in %d sec." % TIMEOUT_SEC,
            })
          rescue JSON::ParserError => ex
            return create_action({
                :type => :error,
                :message => "JSON syntax error: %s" % [ex.message].pack("M").gsub("=\n","") ,
            })
          rescue ValidationError => ex
            return create_action({
                :type => :error,
                :message => ex.message,
            })
            
          end
          
        end
        
        def close()
          @socket.close()
        end
        
    end
    
end
