require File.expand_path(File.dirname(__FILE__) + '/edgecase')

$LOAD_PATH << File.dirname(__FILE__)
require 'about_scoring_project'
require 'about_dice_project'

require 'rubygems'
require 'rr'
#require 'test/unit'

class EdgeCase::Koan
  include RR::Adapters::TestUnit
end

class GreedGame
  attr :dice

  class TurnSequenceError < StandardError ; end

  class Player
    attr_accessor :score, :roll_score, :game, :unscored_dice
    def initialize(game)
      @qualified = false
      @game = game
      @unscored_dice = []
      @roll_score = 0
      @score = 0
    end

    def in_the_game?
      @qualified
    end

    def roll
      if unscored_dice == []
        temp_dice = game.initial_roll
        self.roll_score = game.score(temp_dice, unscored_dice)
        return [self.roll_score, temp_dice, unscored_dice]
      elsif unscored_dice.nil?
        raise TurnSequenceError
      else
        temp_dice = game.continuing_roll(unscored_dice)
        self.roll_score += game.score(temp_dice, unscored_dice)
        return [self.roll_score, temp_dice, unscored_dice] unless temp_dice.size == unscored_dice.size
        return [self.roll_score=0, temp_dice, self.unscored_dice=nil]
      end
    end

  end

  def initialize
    @dice = DiceSet.new
    @players = []
  end

  def initial_roll
    dice.roll(5)
  end

  def continuing_roll(unrolled_dice)
    dice.roll(unrolled_dice.size)
  end

  def new_player
    @players << Player.new(self)
    @players.last
  end

  def score_triples!(dice)
   sum = 0
   group = dice.group_by { |i| i }
   group.each do |die, subgroup|
       if subgroup.size > 2
         sum += 100 * die
         subgroup.pop(3)
       end
     end
     dice.replace(group.values.flatten)
   sum
  end

  def score(dice_orig, unscored_dice=[])
    # You need to write this method
    sum = 0
    dice = dice_orig.dup
    while temp=dice.find_index(HUNDRED_POINT_DIE)
      dice[temp]=HUNDRED_POINT_STANDIN
    end
    if dice.uniq.size <= dice.size - 2
      sum += score_triples!(dice)
    end

    point_die_block = Proc.new {|die| die == HUNDRED_POINT_STANDIN || die == FIFTY_POINT_DIE}
    point_die = dice.select &point_die_block
    point_die.each {|die| sum += die*10}
    dice.reject! &point_die_block
    unscored_dice.replace(dice)
    return sum
  end
end

class AboutExtraCredit < EdgeCase::Koan
  def test_dice_exist
    game = GreedGame.new
    assert_not_nil game.dice
  end

  def test_dice_roll
    game = GreedGame.new
    assert_equal 5, game.initial_roll.size
  end

  def test_dice_score
    game = GreedGame.new
    dice = game.initial_roll
    dice[0], dice[1], dice[2] = 1, 1, 1
    assert_equal true, game.score(dice) > 999
    dice[0], dice[1], dice[2], dice[3], dice[4] = 2, 2, 3, 3, 4
    assert_equal 0, game.score(dice)
  end

  def test_player_creation
    game = GreedGame.new
    player1 = game.new_player
    assert_not_nil player1
  end

  def test_player_roll_and_commit
    game = GreedGame.new
    player1 = game.new_player
    assert_equal false, player1.in_the_game?
    stub(game).initial_roll.returns([5,2,3,3,4])
    assert_equal [50, [5,2,3,3,4], [2,3,3,4]], player1.roll
    stub(game).initial_roll {[5,5,5,3,4]} ; player1.unscored_dice=[]
    assert_equal [500, [5,5,5,3,4], [3,4]], player1.roll
    stub(game).continuing_roll {[1,3]}
    assert_equal [600, [1,3], [3]], player1.roll
    stub(game).continuing_roll {[4]}
    assert_equal [0, [4], nil], player1.roll

    stub(game).initial_roll {[5,5,5,3,4]} ; player1.unscored_dice=[]
    assert_equal [500, [5,5,5,3,4], [3,4]], player1.roll

  end
end


# EXTRA CREDIT:
#
# Create a program that will play the Greed Game.
# Rules for the game are in GREED_RULES.TXT.
#
# You already have a DiceSet class and score function you can use.
# Write a player class and a Game class to complete the project.  This
# is a free form assignment, so approach it however you desire.
