require 'test_helper'
require 'AuthenticationHelper'

class SitesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticationHelper

  setup do
    @user = users(:one)
    @user.confirm
    sign_in(@user.email, 'password')

    @site = sites(:one)
  end

  test "should show site" do
    get site_url(@site), as: :json
    assert_response :unauthorized

    authentication_get @user, site_url(@site), as: :json
    assert_response :success

    assert_equal(@site.to_json, response.body)
  end

  test "should update site" do
    new_url = 'new_url'

    patch site_url(@site), params: { site: { url: new_url } }, as: :json
    assert_response :unauthorized

    authentication_patch @user, site_url(@site), params: { site: { url: new_url } }, as: :json
    assert_response 200

    response_body = JSON.parse(response.body)
    expected_json = @site.as_json.merge(
      {
        url: new_url,
        created_at: response_body['created_at'],
        updated_at: response_body['updated_at']
      }
    ).to_json
    assert_equal(expected_json, response.body);
  end

  test "should destroy site" do
    assert_no_difference('Site.count', -1) do
      delete site_url(@site), as: :json
    end

    assert_difference('Site.count', -1) do
      authentication_delete @user, site_url(@site), as: :json
    end

    assert_response 204
  end
end
