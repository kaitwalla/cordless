require "test_helper"

class CustomEmojisControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "once.cordless.test"
    sign_in :david
  end

  test "index lists custom emojis" do
    emoji = create_custom_emoji("test_emoji")

    get custom_emojis_url
    assert_response :success
    assert_select "code", text: ":test_emoji:"
  end

  test "new shows form" do
    get new_custom_emoji_url
    assert_response :success
    assert_select "form"
  end

  test "create creates emoji for any user" do
    sign_in :jz # Non-admin user

    assert_difference "CustomEmoji.count", 1 do
      post custom_emojis_url, params: {
        custom_emoji: {
          shortcode: "my_emoji",
          image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
        }
      }
    end

    assert_redirected_to custom_emojis_url
    assert_equal "my_emoji", CustomEmoji.last.shortcode
  end

  test "create with invalid params renders new" do
    post custom_emojis_url, params: {
      custom_emoji: { shortcode: "" }
    }

    assert_response :unprocessable_entity
  end

  test "destroy removes emoji for admin" do
    emoji = create_custom_emoji("delete_me")

    assert_difference "CustomEmoji.count", -1 do
      delete custom_emoji_url(emoji)
    end

    assert_redirected_to custom_emojis_url
  end

  test "destroy forbidden for non-admin" do
    sign_in :jz
    emoji = create_custom_emoji("protected")

    assert_no_difference "CustomEmoji.count" do
      delete custom_emoji_url(emoji)
    end

    assert_response :forbidden
  end

  private

  def create_custom_emoji(shortcode)
    CustomEmoji.create!(
      shortcode: shortcode,
      creator: users(:david),
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )
  end
end
