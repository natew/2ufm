class Station < ActiveRecord::Base

  def to_param
    url
  end
end
