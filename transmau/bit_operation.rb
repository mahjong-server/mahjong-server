module BitOperation
  LOWORD_MASK = 0x0000_ffff
  HIWORD_MASK = 0xffff_0000
  WORD_BITS   = 16

  def loword(bit)
    bit & LOWORD_MASK
  end

  def hiword(bit)
    (bit & HIWORD_MASK) >> WORD_BITS
  end

  def make_lparam(hiword, loword)
    (LOWORD_MASK | HIWORD_MASK) & ((hiword << WORD_BITS) | (loword & LOWORD_MASK))
  end
end

