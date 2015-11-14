require "mjai/player"
require "mjai/archive"


module Mjai
    
    class ArchivePlayer < Player
        
        def initialize(archive_path)
          super()
          @archive = Archive.load(archive_path)
          @archive.trimnewdora!
          @action_index = 0
          @id = nil
        end
        
        def update_state(action)
          super(action)
          expected_action = @archive.actions[@action_index]
          if [:dora].include?(action.type)
            # チェックもカウンタ進めもしない
            return
          end
          
          if (action.type == expected_action.type)
            if action.type == :start_game
              @id = action.id
              expected_action = expected_action.merge({:id => @id})
            elsif action.type == :hora
              [:uradora_markers, :hora_tehais, :yakus].map{|x|
                action.public_send(x).sort!
                expected_action.public_send(x).sort!
              }
              
              if expected_action.fan >= 100 #役満のときの数値を適当にあわせる
                expected_action = expected_action.merge({:fan => expected_action.yakus.size * 100})
                
                if expected_action.yakus.include?( [:kokushimuso, 100] )
                  expected_action = expected_action.merge({:fu => 0})
                end
              end
            elsif action.type == :ryukyoku
              4.times{|i|
                action.tehais[i].sort!
                expected_action.tehais[i].sort!
              }
            end
          end
          
          if (action.type != expected_action.type) ||
           ( action.actor && action.actor.id == @id && (action.to_json() != expected_action.to_json()) ) ||
           ( (action.to_json() != expected_action.to_json()) && ![:start_game, :start_kyoku, :tsumo].include?(action.type) )
            raise((
                "live action doesn't match one in archive\n" +
                "actual: %s\n" +
                "expected: %s\n") %
                [action, expected_action])
          end
          @action_index += 1
        end
        
        def respond_to_action(action)
          if [:dora, :hora, :reach_accepted].include?(action.type) then
             return nil
          end
          if action.actor && action.actor.id == @id && action.type == :kakan then
             # 自分の加槓に槍槓することはない
             return nil
          end
          
          next_action = @archive.actions[@action_index]
          nextnext_action = @archive.actions[@action_index+1]
          
          
          # ダブロン
          if next_action && next_action.type == :hora &&
              nextnext_action && nextnext_action.type == :hora &&
              nextnext_action.actor.id == @id
              return Action.from_json(nextnext_action.to_json(), self.game)
          end
          
          # リーチ宣言牌を鳴く
          if next_action && next_action.type == :reach_accepted
            next_action = nextnext_action
          end
          
          if next_action &&
              next_action.type == :ryukyoku && next_action.reason == :sanchaho &&
              action.actor.id != @id
              # 三家和のときは三人のロン発声をエミュレートする
              return Action.new({:type => :hora, :actor => self, :target => action.actor, :pai => action.pai})
          end
          
          # 流局のうち、プレイヤからの発声は九種九牌のみ
          if next_action && next_action.type == :ryukyoku && next_action.reason == :kyushukyuhai &&
            action.actor.id == @id
            return Action.new({:type => :ryukyoku, :actor => self, :reason => :kyushukyuhai})
          end
          
          if next_action &&
              next_action.actor &&
              next_action.actor.id == @id &&
              [:dahai, :chi, :pon, :daiminkan, :kakan, :ankan, :reach, :hora].include?(
                  next_action.type)
            return Action.from_json(next_action.to_json(), self.game)
          else
            return nil
          end
        end
        
    end
    
end
