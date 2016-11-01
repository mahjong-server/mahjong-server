require 'mjai/pai.rb'

module TransMaujong
  module MJPI
    INITIALIZE     =  1
    SUTEHAI        =  2
    ONACTION       =  3
    STARTGAME      =  4
    STARTKYOKU     =  5
    ENDKYOKU       =  6
    ENDGAME        =  7
    DESTROY        =  8
    YOURNAME       =  9
    CREATEINSTANCE = 10
    BASHOGIME      = 11
    ISEXCHANGEABLE = 12
    ONEXCHANGE     = 13
  end

  module MJMI
    GETTEHAI         =  1
    GETKAWA          =  2
    GETDORA          =  3
    GETSCORE         =  4
    GETHONBA         =  5
    GETREACHBOU      =  6
    GETRULE          =  7
    GETVERSION       =  8
    GETMACHI         =  9
    GETAGARITEN      = 10
    GETHAIREMAIN     = 11
    GETVISIBLEHAIS   = 12
    FUKIDASHI        = 13
    KKHAIABILITY     = 14
    GETWAREME        = 15
    SETSTRUCTTYPE    = 16
    SETAUTOFUKIDASHI = 17
    LASTTSUMOGIRI    = 18
    SSPUTOABILITY    = 19
    GETYAKUHAN       = 20
    GETKYOKU         = 21
    GETKAWAEX        = 22
    ANKANABILITY     = 23
  end

  module MJPIR
    NO_AKA5   = 0x0000_0001
    HAI_MASK  = 0x0000_00ff
    NAKI_MASK = 0xffff_ff00
    SUTEHAI   = 0x0000_0100
    REACH     = 0x0000_0200
    KAN       = 0x0000_0400
    TSUMO     = 0x0000_0800
    NAGASHI   = 0x0000_1000
    PON       = 0x0000_2000
    CHII1     = 0x0000_4000
    CHII2     = 0x0000_8000
    CHII3     = 0x0001_0000
    MINKAN    = 0x0002_0000
    ANKAN     = 0x0004_0000
    RON       = 0x0008_0000
    ERROR     = 0x8000_0000
  end

  module MJRL
    KUITAN         =  1
    KANSAKI        =  2
    PAO            =  3
    RON            =  4
    MOCHITEN       =  5
    BUTTOBI        =  6
    WAREME         =  7
    AKA5           =  8
    SHANYU         =  9
    SHANYU_SCORE   = 10
    KUINAOSHI      = 11
    AKA5S          = 12
    URADORA        = 13
    SCORE0REACH    = 14
    RYANSHIBA      = 15
    DORAPLUS       = 16
    FURITEN_REACH  = 17
    NANNYU         = 18
    NANNYU_SCORE   = 19
    KARATEN        = 20
    PINZUMO        = 21
    NOTENOYANAGARE = 22
    KANINREACH     = 23
    TOPOYAAGARIEND = 24
    KIRIAGE_MANGAN = 25
    DBLRONCHONBO   = 26

  end
  
  module MJR
    NOTCARED       = 0xffff_ffff
  end

  module MJEK
    AGARI    = 1
    RYUKYOKU = 2
    CHONBO   = 3
  end

  module MJST
    INKYOKU   = 1
    BASHOGIME = 2
  end

  module MJKS
    REACH = 1
    NAKI  = 2
  end

  class Mjai::Pai
    @@offset_map = {"m" => 0, "p" => 9 , "s" => 18, "t" => 27}

    # Mjai::Pai -> Pai number
    def to_mau_i
      # Maujong defines pai's id below
      # 1m, ..., 9m, 1p, ..., 9p, 1s, ..., 9s,  E,  S,  W,  N,  P,  F,  C
      #  0, ...,  8,  9, ..., 17, 18, ..., 26, 27, 28, 29, 30, 31, 32, 33
      @number + @@offset_map[@type] - 1
    end

    def to_mau_i_r
      red_offset = (@red) ? 64 : 0

      @number + @@offset_map[@type] - 1 + red_offset
    end

    # Pai number -> Mjai::Pai
    def self.from_mau_i(pai_number)
      red  = false
      type = nil

      # number of red hais is added by 64
      if [68, 77, 86].include?(pai_number) then
        red = true
        pai_number = pai_number - 64
      end

      case pai_number
      when 0..8
        pai_number = pai_number -  0 + 1
        type = "m"
      when 9..17
        pai_number = pai_number -  9 + 1
        type = "p"
      when 18..26
        pai_number = pai_number - 18 + 1
        type = "s"
      when 27..33 
        pai_number = pai_number - 27 + 1
        type = "t"
      else 
        raise(ArgumentError, "wrong pai number: #{pai_number}")
      end

      Mjai::Pai.new(type, pai_number, red)
    end
  end

end
