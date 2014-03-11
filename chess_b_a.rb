require 'debugger'

class Piece
  attr_accessor :position
  attr_reader :colour, :board, :moves

  def initialize(position, board, colour)
    @position, @board, @colour = position, board, colour
  end

  def moves
    #make in sublasses and raise error in superclass
  end

  def on_board?(pos)
    pos.all? do |coord|
      coord.between?(0,7)
    end
  end

  def allied_collision?(pos)
    return false if @board[pos].nil?
    @board[pos].colour == @colour
  end

  def capture_options(moves)
    capture_options = []
    moves.each { |pos| capture_options << pos if capture_opportunity?(pos) }
    capture_options
  end

  def capture_opportunity?(pos)
    square = @board[pos]
    return false if square.nil?
    square.colour != @colour #returns true if enemy
  end

  def render
    return "[#{colour},K]" if self.class == King
    return "[#{colour},Q]" if self.class == Queen
    return "[#{colour},p]" if self.class == Pawn
    return "[#{colour},b]" if self.class == Bishop
    return "[#{colour},k]" if self.class == Knight
    return "[#{colour},r]" if self.class == Rook
  end

  def deltas
    self.class::DELTAS
  end

end

# myboard[0,2] would return the piece at that position on the board

class SlidingPiece < Piece
  #method that gets HOW the piece moves, intakes "move_dirs"

  #method that determines if other pieces are in the way
  # => filters the move set

  def moves
    moves = []

    deltas.each do |direction|
      dx, dy = direction[0], direction[1]
      x, y = @position[0], @position[1]
      move = [x + dx, y + dy]

      until !on_board?(move) || allied_collision?(move)
        moves << move
        break if capture_opportunity?(move)
        move  = [move[0] + dx, move[1] + dy]
      end
    end

    moves
  end
end

class Bishop < SlidingPiece
 DELTAS = [
    [1 , 1],
    [1 ,-1],
    [-1, 1],
    [-1,-1]
  ]
end

class Rook < SlidingPiece
  DELTAS = [
    [1, 0],
    [0, 1],
    [-1,0],
    [0,-1]
  ]

end

class Queen < SlidingPiece
  DELTAS = [
    [1, 0],
    [0, 1],
    [-1,0],
    [0,-1],
    [1 , 1],
    [1 ,-1],
    [-1, 1],
    [-1,-1]
  ]

end


class SteppingPiece < Piece

  def moves
    moves = []
    all_moves = all_pos_moves
    all_moves.each do |pos|
      moves << pos if on_board?(pos) && !allied_collision?(pos)
    end

    moves
  end

  def all_pos_moves
    x, y = @position[0], @position[1]
    all_pos_moves = []
    deltas.each do |delta|
      dx, dy = delta[0], delta[1]
      all_pos_moves << [x+ dx, y + dy]
    end

    all_pos_moves
  end

end

class King < SteppingPiece
  DELTAS = [
    [-1, -1],
    [-1,  0],
    [-1,  1],
    [ 0, -1],
    [ 0,  1],
    [ 1, -1],
    [ 1,  0],
    [ 1,  1]
    ]

end

class Knight < SteppingPiece
  DELTAS = [
    [-2, -1],
    [-2,  1],
    [-1, -2],
    [-1,  2],
    [ 1, -2],
    [ 1,  2],
    [ 2, -1],
    [ 2,  1]
  ]

end


class Pawn < Piece
  def moves
    moves = []
    x, y = @position[0], @position[1]
    if x == 1 || 6 #leap forwards
      move = [x, y + 2]
      moves << move if [x, y + 1].nil? && move.nil?
    end
    moves << [x, y + 1] if [x, y + 1].nil? #one step
    moves << [x+1, y+1] if capture_opportunity?([x+1, y+1]) #cap r
    moves << [x-1, y+1] if capture_opportunity?([x-1, y+1]) #cap l
  end
end

class Board
  attr_accessor :board

  def initialize(populate=true)
    @board = Array.new(8) {Array.new(8)}
    setup_board if populate
  end

  def setup_board
    setup_pawns
    setup_back
  end

  def setup_pawns
    board.each_index do |row|
      self[[row, 1]] = Pawn.new([row,1], self, :W)
      self[[row, 6]] = Pawn.new([row,6], self, :B)
    end
  end

  def setup_back
    [0,7].each do |col|
      colour = (col == 0 ? :W : :B)
      self[[0, col]] = Rook.new(  [0, col], self, colour)
      self[[7, col]] = Rook.new(  [7, col], self, colour)
      self[[1, col]] = Knight.new([1, col], self, colour)
      self[[6, col]] = Knight.new([6, col], self, colour)
      self[[2, col]] = Bishop.new([2, col], self, colour)
      self[[5, col]] = Bishop.new([5, col], self, colour)
      self[[3, col]] = King.new(  [3, col], self, colour)
      self[[4, col]] = Queen.new( [4, col], self, colour)
    end
  end

  def in_check?(colour)
    king_pos = find_king(colour)
    check_enemy_moves(colour, king_pos)
  end

  def find_king(colour)
    board.flatten.each do |square|
      next if square.nil?
      if square.class == King && square.colour == colour
        return square.position
      end
    end
    nil
  end

  def check_enemy_moves(colour, position)
    enemy_colour = (colour== :W ? :B : :W)

    board.flatten.each do |square|
      next if square.nil?
      if square.class != King && square.colour == enemy_colour
        return true if square.moves.include?(position)
      end
    end
    false
  end


  def render
    board.each_with_index do |row,idx1|
      render_string = ""
      row.each_index do |idx2|
        piece = self[[idx1, idx2]]
        if piece.nil?
          render_string += "[___]"
        else
          render_string += piece.render
        end
      end
      puts render_string
    end
    nil
  end

  def [](pos)
    row, col = pos
    @board[row][col]
  end

  def []=(pos, value)
    row, col = pos
    @board[row][col] = value
  end

end

