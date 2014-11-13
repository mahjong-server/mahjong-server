module Mjai
    
    class ValidationError < StandardError
    end
    
    class GameFailError < StandardError
        attr_reader(:player)
        attr_reader(:response)
        
        def initialize(message, player, response)
            super(message)
            @player = player
            @response = response
        end
    end
    
end
