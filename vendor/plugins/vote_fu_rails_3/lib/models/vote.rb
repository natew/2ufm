class Vote < ActiveRecord::Base

  scope :for_voter,    lambda { |*args| where(["voter_id = ? AND voter_type = ?", args.first.id, args.first.type.name]) }
  scope :for_voteable, lambda { |*args| where(["voteable_id = ? AND voteable_type = ?", args.first.id, args.first.type.name]) }
  scope :recent,       lambda { |*args| where(["created_at > ?", (args.first || 2.weeks.ago).to_s(:db)]) }
  scope :descending, order("created_at DESC")

  # NOTE: Votes belong to the "voteable" interface, and also to voters
  belongs_to :voteable, :polymorphic => true
  belongs_to :voter,    :polymorphic => true

  attr_accessible :vote, :voter, :voteable

  # Uncomment this to limit users to a single vote on each item.
  # validates_uniqueness_of :voteable_id, :scope => [:voteable_type, :voter_type, :voter_id]

end
