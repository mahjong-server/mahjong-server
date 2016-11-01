require "mjai/game"
require "mjai/action"
require "mjai/hora"
require "mjai/validation_error"

require "mjai/archive_player"


module Mjai

    class ReplayGame < ActiveGame
        
        def initialize(archive_path)
            super((0...4).map(){ ArchivePlayer.new(archive_path) })
            @archive = Archive.load(archive_path)
            
            @action_index = 0
        end
        
        def play()
        
            @arcpais = []
            arcpos = -1
            for act in @archive.actions do
                if act.type == :start_kyoku then
                    arcpos += 1
                    @arcpais.push( {:pipais => [], :dora => [act.dora_marker], :uraadded => false} )
                    for pp in act.tehais do
                        for tp in pp do
                            @arcpais[arcpos][:pipais].unshift(tp)
                        end
                    end
                elsif act.type == :tsumo then
                    @arcpais[arcpos][:pipais].unshift(act.pai)
                elsif act.type == :dora  then
                    @arcpais[arcpos][:dora].unshift(act.dora_marker)
                elsif act.type == :hora  then
                    if @arcpais[arcpos][:uraadded] == false && act.uradora_markers.size >0 then
                        for up in act.uradora_markers do
                            @arcpais[arcpos][:dora].unshift(up)
                        end
                        @arcpais[arcpos][:uraadded] = true
                    end
                end
            end
            
            for arck in @arcpais do
                (122 - arck[:pipais].size).times { arck[:pipais].unshift("X?X") }
                (14 - arck[:dora].size).times { arck[:dora].unshift("Y?Y") }
            end
            
            if @archive.actions[0].type != :start_game
                raise "first action is not start_game"
            end
            @game_type = @archive.actions[0].gametype
            
            4.times { |i| self.players[i].name = @archive.actions[0].names[i] }
            
            begin
              do_action({:type => :start_game, :names => self.players.map(){ |pl| pl.name }})
              @ag_oya = @ag_chicha = @players[0]
              @ag_bakaze = Pai.new("E")
              @ag_honba = 0
              @ag_kyotaku = 0
              
              @rep_arcpos = 0
              while !self.game_finished?
              
                print @rep_arcpos, " "
                play_kyoku()
                
                print @bakaze, @kyoku_num, "-", @honba
                print " "
                print self.get_scores([0,0,0,0])
                print "\n"
                @rep_arcpos += 1
              end
              
              fin_score = get_final_scores()
              do_action({:type => :end_game, :scores => fin_score})
              
              print "final " , fin_score, "\n"
              return fin_score
            rescue GameFailError
              do_action({:type => :error, :message => "Player" + $!.player.to_s + "'s illegal response: " + $!.message})
              raise $!
            end
        end
        
        
        def play_kyoku()
          catch(:end_kyoku) do
            @pipais = @arcpais[@rep_arcpos][:pipais]
            @wanpais = @arcpais[@rep_arcpos][:dora]
            dora_marker = @wanpais.pop()
            tehais = Array.new(4){ @pipais.pop(13).sort() }
            do_action({
                :type => :start_kyoku,
                :bakaze => @ag_bakaze,
                :kyoku => (4 + @ag_oya.id - @ag_chicha.id) % 4 + 1,
                :honba => @ag_honba,
                :kyotaku => @ag_kyotaku,
                :oya => @ag_oya,
                :dora_marker => dora_marker,
                :tehais => tehais,
            })
            @actor = self.oya
            while !@pipais.empty?
              mota()
              @actor = @players[(@actor.id + 1) % 4]
            end
            process_fanpai()
          end
          do_action({:type => :end_kyoku})
        end
        
        
        def expect_response_from?(player)
          return true
        end
        
    end
end

