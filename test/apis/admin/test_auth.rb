require_relative "../../test_helper"

class Test::Apis::Admin::TestAuth < Minitest::Test
  include ApiUmbrellaTestHelpers::AdminAuth
  include ApiUmbrellaTestHelpers::Setup

  def setup
    super
    setup_server
  end

  def test_unauthenticated
    FactoryGirl.create(:admin)
    response = Typhoeus.get("https://127.0.0.1:9081/admin/auth", keyless_http_options)
    assert_response_code(200, response)
    body = response.body
    data = MultiJson.load(body)

    assert_equal([
      "authenticated",
    ].sort, data.keys.sort)

    assert_equal(false, data["authenticated"])
  end

  def test_authenticated
    response = Typhoeus.get("https://127.0.0.1:9081/admin/auth", keyless_http_options.deep_merge(admin_session))
    assert_response_code(200, response)
    body = response.body
    data = MultiJson.load(body)

    assert_equal([
      "admin",
      "admin_auth_token",
      "analytics_timezone",
      "api_key",
      "api_umbrella_version",
      "authenticated",
      "enable_beta_analytics",
      "local_auth_enabled",
      "password_length_min",
      "username_is_email",
    ].sort, data.keys.sort)

    assert_kind_of(Hash, data["admin"])
    assert_kind_of(String, data["admin_auth_token"])
    assert_kind_of(String, data["analytics_timezone"])
    assert_kind_of(String, data["api_key"])
    assert_kind_of(String, data["api_umbrella_version"])
    assert_includes([TrueClass, FalseClass], data["authenticated"].class)
    assert_includes([TrueClass, FalseClass], data["enable_beta_analytics"].class)

    assert_equal([
      "email",
      "id",
      "superuser",
      "username",
    ].sort, data["admin"].keys.sort)
    assert_equal(File.read(File.join(API_UMBRELLA_SRC_ROOT, "src/api-umbrella/version.txt")).strip, data["api_umbrella_version"])
    assert_equal(true, data["authenticated"])
  end

  def test_authenticated_no_cross_site_access
    response = Typhoeus.get("https://127.0.0.1:9081/admin/auth", keyless_http_options.deep_merge(admin_session))
    assert_response_code(200, response)
    assert_equal("DENY", response.headers["X-Frame-Options"])
    assert_equal("max-age=0, private, must-revalidate", response.headers["Cache-Control"])
    assert_nil(response.headers["Access-Control-Allow-Credentials"])
  end
end
