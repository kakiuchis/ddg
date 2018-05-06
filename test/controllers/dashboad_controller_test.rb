require 'test_helper'

class DashboadControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get dashboad_index_url
    assert_response :success
  end

end
