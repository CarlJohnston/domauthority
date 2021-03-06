require 'uri'

require 'test_helper'
require 'authentication_helper'

class Users::Current::SitesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticationHelper

  setup do
    @user = users(:one)
    assert_not_empty(@user.sites)
    @user_no_sites = users(:three)
    assert_empty(@user_no_sites.sites)
    @user.confirm

    @site = sites(:one)
    @user_sites = @site.user_sites
    @user_site_one_one = user_sites(:one_one)

    @user_alternate = users(:two)
  end

  test "index should only be available for authenticated users" do
    get users_current_sites_url, as: :json
    assert_response :unauthorized
  end

  test "should get index" do
    authentication_get @user, users_current_sites_url, as: :json
    assert_response :success
  end

  test "should list no sites for current user with no sites" do
    authentication_get @user_no_sites, users_current_sites_url, as: :json
    assert_response :success

    assert_equal([].to_json, response.body)
  end

  test "should list sites for current user with some subset of sites" do
    # need more total sites than targeted users sites
    assert(Site.all.count - UserSite.where(user_id: @user.id).pluck(:site_id).uniq.count > 0)

    authentication_get @user, users_current_sites_url, as: :json
    assert_response :success

    assert_equal(@user.sites.to_json, response.body)
  end

  test "should include titles based on current user" do
    # need more user sites for site under test
    assert_not_equal(@user_sites.length, UserSite.where(site_id: @site.id))

    authentication_get @user, users_current_sites_url, as: :json
    assert_response :success

    parsed_response = JSON.parse(response.body)

    parsed_response.each do |parsed_response_site|
      assert_equal(parsed_response_site["title"], UserSite.find_by(site_id: parsed_response_site["id"], user_id: @user.id).title)
    end
  end

  test "should be unprocessable when requested include resource not available when requesting sites" do
    authentication_get @user, users_current_sites_url, params: { include: [ "blah" ] }, as: :json
    assert_response :unprocessable_entity
  end

  test "should include metrics when querying sites and requesting for metrics" do
    sites = @user.sites
    user_site_ids = sites.map(&:id)

    # xhr: true rather than as: :json for now to prevent Rails 5.x from POSTing due to bug
    authentication_get @user, users_current_sites_url, params: { include: [ "metrics" ] }, xhr: true
    assert_response :success

    parsed_response = JSON.parse(response.body)

    assert_equal(user_site_ids, parsed_response.map { |x| x["id"] })
    sites.each do |site|
      json_site_with_metrics = site.as_json({ include: [ "metrics" ] }).to_json
      assert(parsed_response.any? {
               |parsed_response_site| parsed_response_site.to_json.eql?(json_site_with_metrics)
             })
    end
  end

  test "should not include metrics when querying sites and requesting for metrics" do
    authentication_get @user, users_current_sites_url, as: :json
    assert_response :success
    parsed_response = JSON.parse(response.body)
    parsed_response.each do |site|
      assert_not(site["metrics"])
    end
  end

  test "create only available to logged in users" do
    assert_no_difference('Site.count') do
      post users_current_sites_url, params: { site: { url: 'http://www.newurl.com', title: 'new' } }, as: :json
    end
    assert_response :unauthorized
  end

  test "create with bad site params takes no action" do
    new_title = 'new'

    user = @user

    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { random: { url: 'http://www.newurl.com', title: new_title } }, as: :json
      end
    end
    assert_response :unprocessable_entity

    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: {} }, as: :json
      end
    end
    assert_response :unprocessable_entity
  end

  test "create with missing title but proper url uses base URL as title" do
    new_url = 'http://www.newurl.com/'

    user = @user

    assert_difference('Site.count') do
      assert_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: { url: new_url } }, as: :json
      end
    end
    assert_response :created

    new_user_site = UserSite.last
    assert_equal(URI(new_url).host, new_user_site.title)
    assert_equal(user.id, new_user_site.user_id)
  end

  test "create with improper url and no title" do
    new_url = true

    user = @user

    assert_difference('Site.count') do
      assert_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: { url: new_url } }, as: :json
      end
    end
    assert_response :created

    new_user_site = UserSite.last
    assert_equal('', new_user_site.title)
    assert_equal(user.id, new_user_site.user_id)
  end

  test "should create site and user_site for authenticated user with new global site and new for user" do
    user = @user
    new_title = 'new'
    assert_difference('Site.count') do
      assert_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: { url: 'http://www.newurl.com', title: new_title } }, as: :json
      end
    end
    assert_response :created
    parsed_response = JSON.parse(response.body)
    assert(parsed_response["id"])
    assert(parsed_response["title"])
    assert(parsed_response["url"])

    new_user_site = UserSite.last
    assert_equal(new_title, new_user_site.title)
    assert_equal(user.id, new_user_site.user_id)
  end

  test "should only create site user_site for authenticated user with previous global site and no previous user_site for user" do
    new_url = 'http://www.newurl.com'
    new_title = 'new'

    previous_site = Site.create(url: new_url)

    user = @user

    assert_no_difference('Site.count') do
      assert_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: { url: new_url, title: new_title } }, as: :json
      end
    end
    assert_response :created
    parsed_response = JSON.parse(response.body)
    assert(parsed_response["id"])
    assert_equal(new_title, parsed_response["title"])
    assert(parsed_response["url"])

    new_user_site = UserSite.last
    assert_equal(new_title, new_user_site.title)
    assert_equal(user.id, new_user_site.user_id)

    assert_equal(previous_site, previous_site.reload)
  end

  test "should return the new current user_site for authenticated user when creating site with previous global site and no previous user_site for user" do
    new_url = 'http://www.newurl.com'
    new_title = 'new'

    user = @user
    other_user = @user_alternate

    previous_site = Site.create(url: new_url)
    UserSite.create(site_id: previous_site.id, user_id: other_user.id, title: new_title + ' from user_alternate')

    assert_no_difference('Site.count') do
      assert_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: { url: new_url, title: new_title } }, as: :json
      end
    end
    assert_response :created
    parsed_response = JSON.parse(response.body)
    assert_equal(new_title, parsed_response["title"])
    assert(parsed_response["url"])

    new_user_site = UserSite.last
    assert_equal(new_title, new_user_site.title)
    assert_equal(user.id, new_user_site.user_id)

    assert_equal(previous_site, previous_site.reload)
  end

  test "should not create site user_site for authenticated user with previous global site and previous user_site for user" do
    new_url = 'http://www.newurl.com'
    new_title = 'new'

    user = @user

    previous_site = Site.create(url: new_url)
    previous_user_site = UserSite.create(user_id: user.id, site_id: previous_site.id, title: 'random')

    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        authentication_post user, users_current_sites_url, params: { site: { url: new_url, title: new_title } }, as: :json
      end
    end
    assert_response :conflict

    assert_equal(previous_site, previous_site.reload)
    assert_equal(previous_user_site, previous_user_site.reload)
  end

  test "unauthorized for unauthenticated requests to delete" do
    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        delete users_current_site_url(@site), as: :json
      end
    end
    assert_response :unauthorized
  end

  test "destroy site successfully when authenticated with extra params" do
    assert_no_difference('Site.count') do
      assert_difference('UserSite.count', -1) do
        authentication_delete @user, users_current_site_url(@site), params: { blah: 'blah' }, as: :json
      end
    end
    assert_response :no_content
  end

  test "should destroy site when authenticated when site exists and authenticated user has relationship to site" do
    assert_no_difference('Site.count') do
      assert_difference('UserSite.count', -1) do
        authentication_delete @user, users_current_site_url(@site), as: :json
      end
    end
    assert_response :no_content
  end

  test "should 404 when deleting site that exists but that user has no relationship to" do
    user = @user_no_sites
    assert_nil(UserSite.find_by(site_id: @site.id, user_id: user.id))

    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        authentication_delete user, users_current_site_url(@site), as: :json
      end
    end
    assert_response :not_found
  end

  test "should 404 when deleting site as authenticated user that does not exist" do
    site_id = 999999999
    assert_nil(Site.find_by(id: site_id))

    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        authentication_delete @user, users_current_site_url(site_id), as: :json
      end
    end
    assert_response :not_found
  end

  test "unauthorized for unauthenticated requests to patch" do
    assert_no_difference('Site.count') do
      assert_no_difference('UserSite.count') do
        patch users_current_site_url(@site), as: :json
      end
    end
    assert_response :unauthorized
  end

  test "should patch valid site title with valid title when site and user site exists" do
    site_previous = @site.clone
    user_site_one_one_previous = @user_site_one_one.clone

    new_title = "new title"
    assert_not_equal(new_title, @user_site_one_one.title)

    assert_no_difference "Site.count" do
      assert_no_difference "UserSite.count" do
        authentication_patch @user, users_current_site_url(@site), params: { site: { title: new_title } }, as: :json
      end
    end
    assert_response :no_content

    assert_equal(site_previous, @site.reload)

    user_site_one_one_expected = user_site_one_one_previous
    user_site_one_one_expected.title = new_title
    assert_equal(user_site_one_one_expected, @user_site_one_one.reload)
  end

  test "should not patch site with invalid information when site and user site exists" do
    site_previous = @site.clone
    user_site_one_one_previous = @user_site_one_one.clone

    new_title = "new title"
    assert_not_equal(new_title, @user_site_one_one.title)

    assert_no_difference "Site.count" do
      assert_no_difference "UserSite.count" do
        authentication_patch @user, users_current_site_url(@site), params: { site: { blah: "blah" } }, as: :json
      end
    end
    assert_response :unprocessable_entity

    assert_equal(site_previous, @site.reload)

    assert_equal(user_site_one_one_previous, @user_site_one_one.reload)

    assert_no_difference "Site.count" do
      assert_no_difference "UserSite.count" do
        authentication_patch @user, users_current_site_url(@site), params: { blah: "blah" }, as: :json
      end
    end
    assert_response :unprocessable_entity

    assert_equal(site_previous, @site.reload)

    assert_equal(user_site_one_one_previous, @user_site_one_one.reload)
  end

  test "should not patch site title when site and user site do not exist" do
    site_id = 99999999999
    assert_not(Site.find_by(id: site_id))
    assert_not(UserSite.find_by(site_id: site_id))

    assert_no_difference "Site.count" do
      assert_no_difference "UserSite.count" do
        authentication_patch @user, users_current_site_url(site_id), params: { site: { title: 'new' } }, as: :json
      end
    end
    assert_response :not_found
  end

  test "should not patch site title when site exists but user site does not exist" do
    @user_sites = UserSite.where(site_id: @site.id, user_id: @user.id)
    if !@user_sites.empty?
      @user_sites.destroy_all
    end

    assert_no_difference "Site.count" do
      assert_no_difference "UserSite.count" do
        authentication_patch @user, users_current_site_url(@site.id), params: { site: { title: 'new' } }, as: :json
      end
    end
    assert_response :not_found
  end
end
