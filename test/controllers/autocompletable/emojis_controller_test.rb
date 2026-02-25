require "test_helper"

class Autocompletable::EmojisControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "once.cordless.test"
    sign_in :david
  end

  test "index returns json with emojis" do
    create_custom_emoji("test_emoji")

    get autocompletable_emojis_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)

    custom = json.find { |e| e["value"] == "test_emoji" }
    assert custom.present?
    assert_equal "custom", custom["type"]
    assert_equal ":test_emoji:", custom["name"]
  end

  test "index filters by query" do
    create_custom_emoji("happy_face")
    create_custom_emoji("sad_face")

    get autocompletable_emojis_url(format: :json, query: "happy")
    assert_response :success

    json = JSON.parse(response.body)
    custom_emojis = json.select { |e| e["type"] == "custom" }

    assert custom_emojis.any? { |e| e["value"] == "happy_face" }
    assert_not custom_emojis.any? { |e| e["value"] == "sad_face" }
  end

  test "index includes unicode emojis" do
    get autocompletable_emojis_url(format: :json, query: "smile")
    assert_response :success

    json = JSON.parse(response.body)
    unicode = json.find { |e| e["type"] == "unicode" }

    assert unicode.present?, "Expected unicode emojis in response"
  end

  test "index with all=true returns emojis grouped by category" do
    create_custom_emoji("test_picker_emoji")

    get autocompletable_emojis_url(format: :json, all: true)
    assert_response :success

    json = JSON.parse(response.body)

    assert json.key?("custom_emojis"), "Expected custom_emojis key"
    assert json.key?("unicode_emojis"), "Expected unicode_emojis key"

    # Check custom emojis
    custom = json["custom_emojis"].find { |e| e["shortcode"] == "test_picker_emoji" }
    assert custom.present?, "Expected custom emoji in response"
    assert custom["sgid"].present?, "Expected sgid in custom emoji"

    # Check unicode emojis by category
    unicode = json["unicode_emojis"]
    assert unicode.key?("smileys"), "Expected smileys category"
    assert unicode["smileys"].is_a?(Array), "Expected smileys to be an array"
    assert unicode["smileys"].first.key?("emoji"), "Expected emoji field in unicode emoji"
    assert unicode["smileys"].first.key?("shortcode"), "Expected shortcode field in unicode emoji"
  end

  test "index with all=true returns all categories" do
    get autocompletable_emojis_url(format: :json, all: true)
    assert_response :success

    json = JSON.parse(response.body)
    unicode = json["unicode_emojis"]

    expected_categories = %w[smileys gestures people hearts animals nature food objects symbols flags activities travel misc]
    expected_categories.each do |category|
      assert unicode.key?(category), "Expected #{category} category"
    end
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
