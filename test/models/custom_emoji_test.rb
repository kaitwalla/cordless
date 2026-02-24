require "test_helper"

class CustomEmojiTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  setup do
    @user = users(:david)
  end

  test "creates a custom emoji with valid attributes" do
    emoji = CustomEmoji.new(
      shortcode: "test_emoji",
      creator: @user,
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )

    assert emoji.valid?
    assert emoji.save
  end

  test "requires shortcode" do
    emoji = CustomEmoji.new(
      creator: @user,
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )

    assert_not emoji.valid?
    assert_includes emoji.errors[:shortcode], "can't be blank"
  end

  test "requires unique shortcode" do
    CustomEmoji.create!(
      shortcode: "unique_emoji",
      creator: @user,
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )

    duplicate = CustomEmoji.new(
      shortcode: "unique_emoji",
      creator: @user,
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:shortcode], "has already been taken"
  end

  test "shortcode format validation" do
    valid_shortcodes = %w[happy smile_face party-time cool123]
    invalid_shortcodes = [ "UPPERCASE", "with spaces", "special!", "unicode🎉" ]

    valid_shortcodes.each do |shortcode|
      emoji = CustomEmoji.new(shortcode: shortcode, creator: @user)
      emoji.valid?
      assert_not_includes emoji.errors[:shortcode], "only allows lowercase letters, numbers, underscores, and hyphens",
        "Expected #{shortcode} to be valid"
    end

    invalid_shortcodes.each do |shortcode|
      emoji = CustomEmoji.new(shortcode: shortcode, creator: @user)
      emoji.valid?
      assert_includes emoji.errors[:shortcode], "only allows lowercase letters, numbers, underscores, and hyphens",
        "Expected #{shortcode} to be invalid"
    end
  end

  test "requires image" do
    emoji = CustomEmoji.new(shortcode: "test", creator: @user)

    assert_not emoji.valid?
    assert_includes emoji.errors[:image], "can't be blank"
  end

  test "filtered_by returns matching emojis" do
    emoji1 = CustomEmoji.create!(
      shortcode: "happy_face",
      creator: @user,
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )
    emoji2 = CustomEmoji.create!(
      shortcode: "sad_face",
      creator: @user,
      image: fixture_file_upload("test/fixtures/files/earth.png", "image/png")
    )

    results = CustomEmoji.filtered_by("happy")
    assert_includes results, emoji1
    assert_not_includes results, emoji2
  end

  test "attachable_plain_text_representation returns shortcode format" do
    emoji = CustomEmoji.new(shortcode: "test")
    assert_equal ":test:", emoji.attachable_plain_text_representation(nil)
  end
end
