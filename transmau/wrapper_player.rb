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
    def initialize
      super()
    end

    def respond_to_action(action)
      response =
        case action.type
        when :start_game                then on_game_start
        when :end_game                  then on_game_end
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
    end

    def on_reach(action)
      return nil if action.actor != self

      unless @declaration_tile then
        raise(ArgumentError, "reach declaration tile not found") 
      end
    end

    def on_chow(action)
    end

    def on_pong(action)
    end

    def on_kong(action)
    end

    def on_discard(action)
    end

    def on_hora(action)
    end

    def on_round_start(action)
    end

    def on_round_end(action)
    end

    def on_game_start
    end

    def on_game_end
    end
  end
end
