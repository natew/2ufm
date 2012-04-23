class Author < ActiveRecord::Base
  ROLES = %w[original remixer featured producer cover mashup]

  belongs_to :song
  belongs_to :artist

  def role?(type)
    role == type.to_s
  end
end
