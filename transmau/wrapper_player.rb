require 'pp'
require 'fiddle/import'

require 'mjai/pai.rb'
require 'mjai/player.rb'
require 'mjai/hora.rb'
require 'mjai/tenpai_analysis.rb'

require './mipiface.rb'
require './bit_operation.rb'

module TransMaujong
  VERSION = 12

  class WrapperPlayer < Mjai::Player
    include BitOperation

    module M extend Fiddle::Importer
      DLLNAME = "plugins/lodoba.dll"

      dlload DLLNAME

      UINT_TYPE   = -Fiddle::TYPE_INT
      UINT_STRING = "unsigned long"

      MJITehai = struct ([
        "#{UINT_STRING} tehai[14]",
        "#{UINT_STRING} tehai_max",
        "#{UINT_STRING} minshun[4]",
        "#{UINT_STRING} minshun_max",
        "#{UINT_STRING} minkou[4]",
        "#{UINT_STRING} minkou_max",
        "#{UINT_STRING} minkan[4]",
        "#{UINT_STRING} minkan_max",
        "#{UINT_STRING} ankan[4]",
        "#{UINT_STRING} ankan_max",

        "#{UINT_STRING} reserved1",
        "#{UINT_STRING} reserved2"
      ])

      MJITehai1 = struct ([
        "#{UINT_STRING} tehai[14]",
        "#{UINT_STRING} tehai_max",
        "#{UINT_STRING} minshun[4]",
        "#{UINT_STRING} minshun_max",
        "#{UINT_STRING} minkou[4]",
        "#{UINT_STRING} minkou_max",
        "#{UINT_STRING} minkan[4]",
        "#{UINT_STRING} minkan_max",
        "#{UINT_STRING} ankan[4]",
        "#{UINT_STRING} ankan_max",

        "#{UINT_STRING} minshun_hai[3][4]",
        "#{UINT_STRING} minkou_hai[3][4]",
        "#{UINT_STRING} minkan_hai[4][4]",
        "#{UINT_STRING} ankan_hai[4][4]",

        "#{UINT_STRING} reserved1",
        "#{UINT_STRING} reserved2"
      ])

      MJIKawahai = struct ([
        "unsigned short hai",
        "unsigned short state"
      ])

      # 3rd and 4th arguments should be able to contain a memory address for the environment where this program will be executed
      # therefore in 64bit environments, they should be able to contain 64bit unsigned integer
      extern "#{UINT_STRING} MJPInterfaceFunc(void *, #{UINT_STRING}, #{UINT_STRING}, #{UINT_STRING})", :stdcall
    end

    module STD extend Fiddle::Importer
      dlload "msvcrt.dll"
      extern 'void * memmove(void *, void *, unsigned long)'
    end

    attr_reader :name

    def initialize
      super()

      alloc_size = M.MJPInterfaceFunc(nil, MJPI::CREATEINSTANCE, 0, 0)

      safe_margin = 1 ** 10
      @instance     = Fiddle.malloc(alloc_size + safe_margin)
      @instance_ptr = Fiddle::Pointer[@instance]
      @struct_type  = 0

      callback_return_type = M::UINT_TYPE
      callback_signature   = [Fiddle::TYPE_VOIDP, -M::UINT_TYPE, -M::UINT_TYPE, -M::UINT_TYPE]

      @callback_closure = Fiddle::Closure::BlockCaller.new(callback_return_type, callback_signature) do |inst, message, p1, p2|
        callback(inst, message, p1, p2)
      end

      callback_addr = Fiddle::Pointer[@callback_closure].to_i

      unless M.MJPInterfaceFunc(nil, MJPI::INITIALIZE, 0, callback_addr) == 0 then
        raise "Initialization of plugin failed"
      end

      @name = Fiddle::Pointer[M.MJPInterfaceFunc(nil, MJPI::YOURNAME, 0, 0)].to_s
    end

    def self.finalizer
      M.MJPInterfaceFunc(nil, MJPI::DESTROY, 0, 0)
      Fiddle.free(@instance)
    end

    def relative_seat_pos(target, base)
      return (4 + target - base) % 4
    end

    def absolute_seat_pos(target, base)
      return (base + target) % 4
    end

    def self.vaild_tile_number?(tile, struct_type)
      if struct_type == 1 then
        [*0..33, 68, 77, 86].include?(tile)
      else
        [*0..33].include?(tile)
      end
    end

    def respond_to_action(action)
      pp action

      response =
        case action.type
        when :start_game                then on_game_start
        when :end_game                  then on_game_end(action)
        when :start_kyoku               then on_round_start(action)
        when :end_kyoku                 then on_round_end(action)
        when :tsumo                     then on_draw(action)
        when :reach                     then on_reach(action)
        when :chi                       then on_chow(action)
        when :pon                       then on_pong(action)
        when :ankan, :daiminkan, :kakan then on_kong(action)
        when :dahai                     then on_discard(action)
        when :hora                      then on_hora(action)
        else                                 nil
        end

      pp response
      return response
    end

    def callback(inst, message, p1, p2)
    	pp message
      case message
      when MJMI::GETTEHAI         then on_get_tehai(p1, p2)
      when MJMI::GETMACHI         then on_get_machi(p1, p2)
      when MJMI::GETAGARITEN      then on_get_agari_ten(p1, p2)
      when MJMI::GETKAWA          then on_get_kawa(p1, p2)
      when MJMI::GETKAWAEX        then on_get_kawa_ex(p1, p2)
      when MJMI::GETDORA          then on_get_dora(p1, p2)
      when MJMI::GETSCORE         then on_get_score(p1, p2)
      when MJMI::GETKYOKU         then on_get_kyoku(p1, p2)
      when MJMI::GETHONBA         then on_get_honba(p1, p2)
      when MJMI::GETREACHBOU      then on_get_reach_bou(p1, p2)
      when MJMI::GETHAIREMAIN     then on_get_hai_remain(p1, p2)
      when MJMI::GETVISIBLEHAIS   then on_get_visible_hais(p1, p2)
      when MJMI::KKHAIABILITY     then on_kk_hai_ability(p1, p2)
      when MJMI::SSPUTOABILITY    then on_ssputo_ability(p1, p2)
      when MJMI::LASTTSUMOGIRI    then on_last_tsumogiri(p1, p2)
      when MJMI::GETRULE          then on_get_rule(p1, p2)
      when MJMI::SETSTRUCTTYPE    then on_set_struct_type(p1, p2)
      when MJMI::FUKIDASHI        then 1
      when MJMI::SETAUTOFUKIDASHI then 0
      when MJMI::GETWAREME        then 0
      when MJMI::GETVERSION       then VERSION
      end
    end

    def on_set_struct_type(p1, p2)
      if [0, 1].include?(p1) then
        old_type = @struct_type
        @struct_type = p1
        return old_type
      end

      return MJRL::NOTCARED
    end

    def on_last_tsumogiri(p1, p2)
      prev = self.game.previous_action

      return (prev.tsumogiri) ? 1 : 0
    end

    def on_get_rule(p1, p2)
      # http://tenhou.net/man/#RULE

      case p1
      when MJRL::KUITAN         then 1
      when MJRL::KANSAKI        then 0
      when MJRL::PAO            then 1 # TODO
      when MJRL::RON            then 1
      when MJRL::MOCHITEN       then 25000
      when MJRL::BUTTOBI        then 1
      when MJRL::WAREME         then 0
      when MJRL::AKA5           then 1
      when MJRL::AKA5S          then 0b001_001_001 # 5sr => 1, 5pr => 1, 5mr => 1
      when MJRL::SHANYU         then 2
      when MJRL::SHANYU_SCORE   then 30000
      when MJRL::NANNYU         then 2
      when MJRL::NANNYU_SCORE   then 30000
      when MJRL::KUINAOSHI      then 0
      when MJRL::URADORA        then 2
      when MJRL::SCORE0REACH    then 0
      when MJRL::RYANSHIBA      then 0
      when MJRL::DORAPLUS       then 1
      when MJRL::FURITENREACH   then 0b11
      when MJRL::KARATEN        then 1
      when MJRL::PINZUMO        then 1
      when MJRL::NOTENOYANAGARE then 0b1111
      when MJRL::KANINREACH     then 2
      when MJRL::TOPOYAAGARIEND then 1
      when MJRL::KIRIAGE_MANGAN then 0
      when MJRL::DBLRONCHONBO   then 0
      else raise(ArgumentError, "Unknown rule: #{p1}")
      end
    end

    def on_get_score(p1, p2)
      target_wind = absolute_seat_pos(p1, self.id)

      return self.game.players[target_wind].score
    end

    def on_get_kyoku(p1, p2)
      return @round
    end

    def on_get_honba(p1, p2)
      return self.game.honba
    end

    def on_get_reach_bou(p1, p2)
      return @reach_bed
    end

    def self.print_mjitehai(mjitehai)
      puts "["
      puts "  [#{mjitehai.tehai_max}]#{mjitehai.tehai}"
      puts "  [#{mjitehai.minshun_max}]#{mjitehai.minshun}"
      puts "  [#{mjitehai.minkou_max}]#{mjitehai.minkou}"
      puts "  [#{mjitehai.minkan_max}]#{mjitehai.minkan}"
      puts "  [#{mjitehai.ankan_max}]#{mjitehai.ankan}"
      puts "]"
    end

    def self.get_mjitehai(tehais_, furos_)
      tehais, furos = tehais_.dup, furos_.dup

      # remove unknown tiles
      tehais.reject! { |p| p.to_s == "?" }

      # remove the tile just drawn in this turn
      tehais.pop if tehais.size % 3 == 2

      type_selector = -> sym, elem { elem.type == sym } .curry

      chows        = furos.select(&type_selector[:minshun])
      pongs        = furos.select(&type_selector[:minkou])
      open_kongs   = furos.select(&type_selector[:daiminkan])
      closed_kongs = furos.select(&type_selector[:ankan])

      mji = M::MJITehai.malloc

      mji.tehai_max   = tehais.size

      mji.minshun_max = chows.size
      mji.minkou_max  = pongs.size
      mji.minkan_max  = open_kongs.size
      mji.ankan_max   = closed_kongs.size

      mji.tehai = [tehais.map(&:to_i), [0] * (14 - mji.tehai_max)].flatten

      least_tile  = -> furo  { [furo.pai, furo.consumed].flatten.min }
      array_maker = -> furos { [furos.map(&:least_tile).map(&:to_i), [0] * (4 - furos.size)].flatten }

      mji.minshun = array_maker[chows]
      mji.minkou  = array_maker[pongs]
      mji.minkan  = array_maker[open_kongs]
      mji.ankan   = array_maker[closed_kongs]

      return mji
    end

    def self.get_mjitehai1(tehais_, furos_)
      tehais, furos = tehais_.dup, furos_.dup

      tehais.reject { |p| p.to_s == "?" }

      type_selector = -> sym, elem { elem.type == sym } .curry

      chows        = furos.select(&type_selector[:minshun])
      pongs        = furos.select(&type_selector[:minkou])
      open_kongs   = furos.select(&type_selector[:daiminkan])
      closed_kongs = furos.select(&type_selector[:ankan])

      mji1 = M::MJITehai1.malloc
      
      mji1.tehai_max   = tehais.size

      mji1.minshun_max = chows.size
      mji1.minkou_max  = pongs.size
      mji1.minkan_max  = open_kongs.size
      mji1.ankan_max   = closed_kongs.size

      mji1.tehai = [tehais.map(&:to_i_r), [0] * (14 - mji1.tehai_max)].flatten

      least_tile  = -> furo  { [furo.pai, furo.consumed].flatten.min }
      array_maker = -> furos { [furos.map(&:least_tile).map(&:to_i_r), [0] * (4 - furos.size)].flatten }

      mji1.minshun = array_maker[chows]
      mji1.minkou  = array_maker[pongs]
      mji1.minkan  = array_maker[open_kongs]
      mji1.ankan   = array_maker[closed_kongs]

      sort_tile = -> furo { [furo.pai, furo.consumed].flatten.sort }
      maker = -> furos, n { [furos.map(&:sort_tile).map(&:to_i_r), [[0] * n] * (4 - furos.size)].reject {|e| e == [] }.transpose.flatten(1) }
 
      minshun = maker[chows, 3]
      minkou  = maker[pongs, 3] 

      for i in 0..2 do
      	mji1.minshun_hai[i] = minshun[i]
      	mji1.minkou_hai[i]  = minkou
      end

      minkan = maker[open_kongs, 4]
      ankan  = maker[closed_kongs, 4]

      for i in 0..3 do
      	mji1.minkan_hai[i] = minkan[i]
      	mji1.ankan_hai[i]  = ankan[i]
      end

      return mji1
    end

    def on_get_tehai(p1, p2)
      target_seat   = absolute_seat_pos(p1, self.id)
      target_player = self.game.players[target_seat]

      mjitehai =
        if @struct_type == 0 then
          WrapperPlayer.get_mjitehai( target_player.tehais, target_player.furos)
        else
          WrapperPlayer.get_mjitehai1(target_player.tehais, target_player.furos)
        end

      STD.memmove(p2, mjitehai, Fiddle::Importer.sizeof(mjitehai))

      Fiddle.free(mjitehai.to_ptr)

      return 0
    end

    def on_get_machi(p1, p2)
      hand =
        if p1 == 0 then
          self.tehais.dup
        else
          mjitehai = M::MJITehai.malloc
          STD.memmove(mjitehai.to_ptr, p1, Fiddle::Importer.sizeof(mjitehai))

          hais = mjitehai.tehai.map do
           |pai| WrapperPlayer.vaild_tile_number?(pai, @struct_type) ? Mjai::Pai.from_i(pai) : nil
          end

          hais.compact[0...mjitehai.tehai_max]
        end

      hand.pop if hand.size % 3 == 2

      result = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * 34)

      for i in 0..33 do
        result[Fiddle::SIZEOF_INT * i] = 0
      end

      ta = Mjai::TenpaiAnalysis.new(hand)

      is_tenpai = ta.tenpai?

      if is_tenpai then
        waited = ta.waited_pais

        waited.each do |pai|
          result[Fiddle::SIZEOF_INT * pai.to_i] = pai.to_i
        end
      end

      STD.memmove(p2, result, Fiddle::SIZEOF_INT * 34)

      return (is_tenpai) ? 1 : 0
    end

    def on_get_visible_hais(p1, p2)
      visibles = self.game.players.map { |player| player.sutehais.map(&:to_i) } .flatten
      return visibles.count(p1)
    end

    def on_get_dora(p1, p2)
      doras = self.game.dora_markers.map { |dora_marker| dora_marker.succ.to_i }

      result = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * 5)

      doras.each_with_index do |dora, i|
        result[Fiddle::SIZEOF_LONG_LONG * i] = dora
      end

      STD.memmove(p1, result, Fiddle::SIZEOF_INT * 5)

      return doras.size
    end

    def on_get_kawa(p1, p2)
      target_id = absolute_seat_pos(loword(p1), self.id)
      target_ho = game.players[target_id].ho

      result_size = [hiword(p1), target_ho.size].min
      result = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * result_size)

      target_ho.each_with_index do |pai, i|
        break if i >= result_size
        result[Fiddle::SIZEOF_INT * i] = pai.to_i
      end

      STD.memmove(p2, result, Fiddle::SIZEOF_INT * result_size)

      return result_size
    end

    def on_get_kawa_ex(p1, p2)
      target_id      = absolute_seat_pos(loword(p1), self.id)
      target_player  = game.players[target_id]
      target_ho      = target_player.ho
      target_sutehais = target_player.sutehais

      reached_tile_index = target_player.reach_ho_index

      kawahai = M::MJIKawahai.malloc
      kawahai_size = Fiddle::Importer.sizeof(kawahai)

      result_size = [hiword(p1), target_sutehais.size].min
      result = Fiddle::Pointer.malloc(kakwahai_size * result_size)

      target_sutehais.each_with_index do |pai, i|
        break if i >= result_size

        kawahai.hai = pai.to_i
        kawahai.state = 0
        kawahai.state |= MJKS::REACH if reached_tile_index && reached_tile_index == i
        kawahai.state |= MJKS::NAKI  unless target_ho.include?(pai)

        result[kawahai_size * i] = kawahai
      end

      STD.memmove(p2, result, kawahai_size * result_size)

      return result_size
    end

    def on_get_hai_remain(p1, p2)
      return self.game.num_pipais
    end

    def on_kk_hai_ability(p1, p2)
      return 0 if self.game.first_turn?

      num_terminals_and_honors = self.tehais.uniq.count { |pai| pai.yaochu? }

      return (num_terminals_and_honors >= 9) ? 1 : 0
    end

    def on_ssputo_ability(p1, p2)
      return 0
    end

    def self.get_tiles(pointer, struct_type)
      mji = M::MJITehai.malloc
      STD.memmove(mji.to_ptr, pointer, Fiddle::Importer.sizeof(mji))

      hand = mji.tehai[0...mji.tehai_max].map { |pai| Mjai::Pai.from_i(pai) }

      transform = -> arr, n, type do
        n > 0 ? nil : arr[0...n].map do
          |pai| Mjai::Furo.from_i(pai, type)
        end
      end

      chows        = transform.call(mji.minshun, mji.minshun_max, :minshun)
      pongs        = transform.call(mji.minkou, mji.minkou_max, :minkou)
      open_kongs   = transform.call(mji.minkan, mji.minkan_max, :minkan)
      closed_kongs = transform.call(mji.ankan, mji.ankan_max, :ankan)

      melds = [chows, pongs, open_kongs, closed_kongs].flatten.compact

      Fiddle.free(mji.to_ptr)

      return [hand, melds]
    end

    def on_get_agari_ten(p1, p2)
      agari_hai = Mjai::Pai.from_i(p2)

      target_pais = []
      target_furos = []

      if p1 == 0 then
        target_pais  = tehais
        target_furos = furos
      else
        target_pais, target_furos = WrapperPlayer.get_tiles(p1, @struct_type)
      end

      target_pais.pop if target_pais.size % 3 == 2

      hora = Mjai::Hora.new({
        :tehais       => target_pais,
        :furos        => target_furos,
        :taken        => agari_hai,

        :oya          => self.game.oya == self,
        :bakaze       => self.game.bakaze,
        :jikaze       => self.jikaze,
        :doras        => self.game.doras,
        :reach        => self.reach?,
        :double_reach => self.double_reach?,
        :hora_type    => :ron,

        # hands based on luck are ignored
        :uradoras => [], :ippatsu => false, :rinshan => false,
        :haitei => false, :first_turn => false, :chankan => false
      })

      return (hora.valid?) ? hora.points : 0
    end

    def on_draw(action)
      @declaration_action = nil

      return nil if action.actor != self

      res = M.MJPInterfaceFunc(@instance_ptr, MJPI::SUTEHAI, action.pai.to_i, 0)

      tile_ind    = res & MJPIR::HAI_MASK # 0x0000**
      next_action = res - tile_ind        # 0x****00

      is_tsumogiri  = tile_ind == 13

      response =
        case next_action
        when MJPIR::SUTEHAI then
          discard_tile_ind = [tile_ind, self.tehais.size - 1].min
          next_tile = self.tehais[discard_tile_ind]
          create_action({:type => :dahai, :pai => next_tile, :tsumogiri => is_tsumogiri})

        when MJPIR::REACH then
          p self.tehais
          next_tile = self.tehais[tile_ind]
          @declaration_action = create_action({:type => :dahai, :pai => next_tile, :tsumogiri => is_tsumogiri})
          create_action({:type => :reach})

        when MJPIR::KAN then
          tile_in_quad = Mjai::Pai.from_i(tile_ind)

          furos = self.possible_furo_actions.select do |f|
            f.type == :ankan && f.consumed.include?(tile_in_quad)
          end

          create_action({:type => :ankan, :consumed => furo.consumed})

        when MJPIR::TSUMO then
          create_action({:type => :hora, :target => self, :pai => action.pai})

        when MJPIR::NAGASHI then
          # TODO: kyuushu kyuhai
          nil

        else
          raise
        end

      return response
    end

    def on_reach(action)
      @reach_bed += 1

      return nil if action.actor != self

      unless @declaration_action then
        raise(ArgumentError, "reach declaration action not found") 
      end

      return @declaration_action
    end

    def on_chow(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      melded   = action.pai.to_i
      consumed = action.consumed.map(&:to_i).sort

      chow_flag = 0

      if melded < consumed.min then
        chi_flag = MJPIR::CHII1
      elsif melded > consumed.max then
        chi_flag = MJPIR::CHII3
      else
        chi_flag = MJPIR::CHII2
      end

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(target_seat, actor_seat), chi_flag | melded)

      return action_after_meld(action)
    end

    def on_pong(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(target_seat, actor_seat), MJPIR::PON | action.pai.to_i)

      return action_after_meld(action)
    end

    def action_after_meld(action)
      return nil if action.actor != self

      tile_number = (action.type == :kan) ? action.pai.to_i : 0xff
      res = M.MJPInterfaceFunc(@instance_ptr, MJPI::SUTEHAI, tile_number, 0)

      tile_id     = res & MJPIR::HAI_MASK
      next_action = res - tile_id

      response =
        case next_action
        when MJPIR::SUTEHAI then
          create_action({:type => :dahai, :pai => self.tehais[tile_id], :tsumogiri => false})

        when MJPIR::TSUMO   then # win by drawing a replacement tile (rinshan-kaiho)
          self.possible_actions.select { |a| a.type == :hora } .first

        when MJPIR::KAN     then
          self.possible_furo_actions.select { |f| f.type == :kan && f.consumed.include?(Mjai::Pai.from_i(tile_id)) } .first

        when MJPIR::REACH, MJPIR::NAGASHI then
          raise(ArgumentError, "invalid action after meld")
        else
          nil
        end

      return response
    end

    def on_kong(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      type = (action.type == :daiminkan) ? MJPIR::MINKAN : MJPIR::ANKAN

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(target_seat, actor_seat), type | action.pai.to_i)

      return action_after_meld(action)
    end

    def on_discard(action)
      actor_seat  = relative_seat_pos(action.actor.id,  id)

      prev = self.game.previous_action

      occured = (prev.type == :reach) ? MJPIR::REACH : MJPIR::SUTEHAI

      res = M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(actor_seat, actor_seat), occured | action.pai.to_i)

      return nil if res == 0

      no_aka5_flag = res & MJPIR::HAI_MASK
      prefer_aka5  = no_aka5_flag == 0
      next_action  = res - no_aka5_flag

      furos = self.possible_furo_actions

      response =
        case next_action
        when MJPIR::RON
          furos.select { |f| f.type == :ron } .first

        when MJPIR::KAN
          furos.select { |f| f.type == :daiminkan } .first

        when MJPIR::PON
          pons = furos.select { |f| f.type == :pon }
          pons.sort_by! { |f| [f.pai, f.consumed].flatten.count { |pai| pai.red? } }

          (prefer_aka5) ? pons.first : pons.last

        when MJPIR::CHII1, MJPIR::CHII2, MJPIR::CHII3
          WrapperPlayer.make_chow(furos, next_action, prefer_aka5)

        else
          nil

        end

      return response
    end

    def self.make_chow(possible_furos, chow_flag, prefer_aka5)
        chis = []

        if chow_flag == MJPIR::CHII1 then
          chis = possible_furos.select { |f| f.type == :chi && f.pai < f.consumed.min }
        elsif chow_flag == MJPIR::CHII2 then
          chis = possible_furos.select { |f| f.type == :chi && f.pai > f.consumed.max }
        else
          chis = possible_furos.select { |f| f.type == :chi }
        end

        chis.sort_by! { |f| [f.pai, f.consumed].flatten.count { |pai| pai.red? } }
        (prefer_aka5) ? chis.first : chis.last
    end

    def on_hora(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      occured = (actor_seat == target_seat) ? MJPIR::TSUMO : MJPIR::RON | action.pai.to_i

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(target_seat, actor_seat), occured)

      return nil
    end

    def on_round_start(action)
      @round   = (action.bakaze.data[1] - 1) * 4 + action.kyoku - 1
      @my_wind = relative_seat_pos(action.oya.id, self.id)
      M.MJPInterfaceFunc(@instance_ptr, MJPI::STARTKYOKU, @round, @my_wind)
      return nil
    end

    def on_round_end(action)
      prev = self.game.previous_action

      reason =
        case prev.type
        when :hora     then MJEK::AGARI
        when :ryukyoku then MJEK::RYUKYOKU
        else                raise
        end

      deltas = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * 4)

      for i in 0..3 do
        deltas[Fiddle::SIZEOF_INT * i] = prev.deltas[i]
      end

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ENDKYOKU, reason, deltas)

      Fiddle.free(deltas)

      @reach_bed = 0 unless reason == MJEK::RYUKYOKU

      return nil
    end

    def on_game_start
      @reach_bed = 0

      M.MJPInterfaceFunc(@instance_ptr, MJPI::STARTGAME, 0, 0)
      return nil
    end

    def on_game_end(action)
      # TODO
      rank, points = 0, 0
      M.MJPInterfaceFunc(@instance_ptr, MJPI::ENDGAME, rank, points)
      return nil
    end
  end
end
