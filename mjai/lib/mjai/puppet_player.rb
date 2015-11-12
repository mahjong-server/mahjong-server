require "mjai/player"


module Mjai
    
    class PuppetPlayer < Player
    
        def initialize(id)
          @id = id
        end
        
        def respond_to_action(action)
          return nil
        end
        
    end
    
end
