require 'test_helper'

class StationTest < ActiveSupport::TestCase
  test "unique slugs" do
    stat1 = Station.create(:title => "Sweet Station")
    assert stat1.valid?, "stat1 was not valid #{stat1.errors.inspect}"

    stat2 = Station.new(:title => "Sweet Station")
    stat2.valid?
    assert_not_nil stat2.errors.on(:slug)
  end
end
