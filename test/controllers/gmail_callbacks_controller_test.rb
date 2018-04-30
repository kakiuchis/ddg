require 'test_helper'

class GmailCallbacksControllerTest < ActionDispatch::IntegrationTest
  test "should get messages" do
    get gmail_callbacks_messages_url
    assert_response :success
  end

end
