module Mjai
    
    class ValidationError < StandardError
    end
    
    class GameFailError < StandardError
        attr_reader(:player)
        attr_reader(:orig_action)
        attr_reader(:response)
        
        def initialize(message, player, orig_action, response)
            super(message)
            @player = player
            @orig_action = orig_action
            @response = response
        end
    end
    
end
