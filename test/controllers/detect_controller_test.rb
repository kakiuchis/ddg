require 'test_helper'

class DetectControllerTest < ActionDispatch::IntegrationTest
  test "should get check" do
    get detect_check_url
    assert_response :success
  end

end
