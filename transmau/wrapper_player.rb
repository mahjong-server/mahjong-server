require 'fiddle/import'

require 'mjai/pai.rb'
require 'mjai/player.rb'
require 'mjai/tcp_client_game.rb'
require 'mjai/tenpai_analysis.rb'
require 'mjai/hora.rb'

require './mipiface.rb'

module TransMaujong
  def relative_seat_pos(target, base)
    (4 + target - baser) % 4
  end

  def absolute_seat_pos(target, base)
    (base + target) % 4
  end

  class WrapperPlayer < Mjai::Player

    module M extend Fiddle::Importer
      DLLNAME = "tilt.dylib"

      dlload DLLNAME

      UINT_TYPE   = Fiddle::TYPE_LONG_LONG
      UINT_STRING = "unsigned long long"

      MJITehai = struct ([
        "#{UINT_STRING} tehai[14]",   # tehai (without furos)
        "#{UINT_STRING} tehai_max",   # #pais in tehai
        "#{UINT_STRING} minshun[4]",  # chi
        "#{UINT_STRING} minshun_max", # #mentsus of chi
        "#{UINT_STRING} minkou[4]",   # pon
        "#{UINT_STRING} minkou_max",  # #mentsus of pon
        "#{UINT_STRING} minkan[4]",
        "#{UINT_STRING} minkan_max",
        "#{UINT_STRING} ankan[4]",
        "#{UINT_STRING} ankan_max",
        "#{UINT_STRING} reserved1",   # reserved for future use
        "#{UINT_STRING} reserved2"
      ])

      MJIKawahai = struct ([
        "unsigned short hai",
        "unsigned short state"
      ])

      # 3rd and 4th arguments should be able to contain a memory address for the environment where this program will be executed
      # therefore in 64bit environments, they should be able to contain 64bit unsigned integer
      extern "#{UINT_STRING} MJPInterfaceFunc(void *, #{UINT_STRING}, #{UINT_STRING}, #{UINT_STRING})", :stdcall

      extern 'void * memmove(void *, void *, unsigned long)'
    end

    def initialize
      super()

      alloc_size = M.MJPInterfaceFunc(nil, MJPI::CREATEINSTANCE, 0, 0)

      @instance     = Fiddle.malloc(alloc_size)
      @instance_ptr = Fiddle::Pointer[@instance]
      @struct_type  = 0

      callback_return_type = UINT_TYPE
      callback_signature   = [Fiddle::TYPE_VOIDP, -UINT_TYPE, -UINT_TYPE, -UINT_TYPE]

      @callback_closure = Fiddle::Closure::BlockCaller.new(callback_return_type, callback_signature) do |inst, messega, p1, p2|
        callback(inst, message, p1, p2)
      end

      callback_addr = Fiddle::Pointer[@callback_closure].to_i

      unless M.MJPInterfaceFunc(nil, MJPI::INITIALIZE, 0, callback_addr) == 0 then
        raise "Initialization of plugin failed"
      end
    end

    def self.finalizer
      M.MJPInterfaceFunc(nil, MJPI::DESTROY, 0, 0)
      Fiddle.free(@instance)
    end

    def respond_to_action(action)
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

      return response
    end

    def callback(inst, message, p1, p2)
      case message
      when MJMI::GETTEHAI       then on_get_tehai(p1, p2)
      when MJMI::GETMACHI       then on_get_machi(p1, p2)
      when MJMI::GETVISIBLEHAIS then on_get_visible_hais(p1, p2)
      when MJMI::GETDORA        then on_get_dora(p1, p2)
      when MJMI::GETKAWA        then on_get_kawa(p1, p2)
      when MJMI::GETKAWAEX      then on_get_kawa_ex(p1, p2)
      when MJMI::GETHAIREMAIN   then on_get_hai_remain(p1, p2)
      when MJMI::KKHAIABILITY   then on_kk_hai_ability(p1, p2)
      when MJMI::SSPUTOABILITY  then on_ssputo_ability(p1, p2)
      when MJMI::GETAGARITEN    then on_get_agari_ten(p1, p2)
      end
    end

    def on_get_tehai(p1, p2)
    end

    def on_get_machi(p1, p2)
    end

    def on_get_visible_hais(p1, p2)
    end

    def on_get_dora(p1, p2)
    end

    def on_get_kawa(p1, p2)
    end

    def on_get_kawa_ex(p1, p2)
    end

    def on_get_hai_remain(p1, p2)
    end

    def on_kk_hai_ability(p1, p2)
    end

    def on_ssputo_ability(p1, p2)
    end

    def on_get_agari_ten(p1, p2)
    end

    def on_draw(action)
      @declaration_action = nil

      return nil if action.actor != self

      res = M.MJPInterfaceFunc(@instance_ptr, MJPI::SUTEHAI, action.pai.to_i, 0)

      tile_ind = res & MJPIR::HAI_MASK
      next_action   = res - next_tile

      is_tsumogiri  = next_tile_ind == 13

      response =
        case next_action
        when MJPIR::SUTEHAI then
          next_tile = self.tehais[tile_ind]
          create_action({:type => :dahai, :pai => next_tile, :tsumogiri => is_tsumogiri})

        when MJPIR::REACH then
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

        else
          raise
        end

      return response
    end

    def on_reach(action)
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

      return nil
    end

    def on_pong(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(target_seat, actor_seat), MJPIR::PON | action.pai.to_i)

      return nil
    end

    def on_kong(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      type = (action.type == :daiminkan) ? MJPIR::MINKAN : MJPIR::ANKAN

      M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(target_seat, actor_seat), type | action.pai.to_i)

      return nil
    end

    def on_discard(action)
      actor_seat  = relative_seat_pos(action.actor.id,  self.id)
      target_seat = relative_seat_pos(action.target.id, self.id)

      prev = self.game.previous_action

      occured = (prev.type == :reach) ? MJPIR::REACH : MJPIR::SUTEHAI

      res = M.MJPInterfaceFunc(@instance_ptr, MJPI::ONACTION, make_lparam(actor_seat, target_seat), occured | action.pai.to_i)

      return nil if res == 0

      prefer_aka5 = (res & MJPIR::HAI_MASK) == 0
      next_action = res - no_aka5_flag

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

        when MJPIR::CHI1, MJPIR::CHI2, MJPIR::CHI3
          make_chow(furos, next_action, prefer_aka5)

        else
          nil

        end

      return response
    end

    def self.make_chow(possible_furos, chow_flag, prefer_aka5)
        chis = []

        if chow_flag == MJPIR::CHI1 then
          chis = possible_furos.select { |f| f.type == :chi && f.taken < f.consumed.min }
        elsif chow_flag == MJPIR::CHI2 then
          chis = possible_furos.select { |f| f.type == :chi && f.taken > f.consumed.max }
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
      round   = (action.bakaze.data[1] - 1) * 4 + action.kyoku - 1
      my_wind = relative_seat_pos(action.oya.id, self.id)
      M.MJPInterfaceFunc(@instance_ptr, MJPI::STARTKYOKU, round, my_wind)
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

      return nil
    end

    def on_game_start
      M.MJPInterfaceFunc(@instance_ptr, MJPI::STARTGAME, 0, 0)
      return nil
    end

    def on_game_end(action)
      # TODO
      rank, points = 0, 0
      M.MJPInterfaceFunc(@instance_ptr, MJPI::ENDGAME, rank, point)
      return nil
    end
  end
end
