require "application_system_test_case"

class MentionsTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "mentioning a user shows autocomplete" do
    join_room rooms(:designers)

    find("[data-controller='composer'] trix-editor").click
    find("[data-controller='composer'] trix-editor").send_keys("@")

    assert_selector "[data-controller='autocomplete']"
    assert_selector ".autocomplete-option", text: "David"
  end

  test "selecting user from autocomplete inserts mention" do
    join_room rooms(:designers)

    find("[data-controller='composer'] trix-editor").click
    find("[data-controller='composer'] trix-editor").send_keys("@Dav")

    click_on "David"

    # The mention should be inserted
    assert_selector "trix-editor .mention", text: "David"
  end

  test "mentioned user receives notification" do
    using_session("David") do
      sign_in "david@37signals.com"
      join_room rooms(:designers)
    end

    join_room rooms(:designers)

    find("[data-controller='composer'] trix-editor").click
    find("[data-controller='composer'] trix-editor").send_keys("@")
    click_on "David"
    find("[data-controller='composer'] trix-editor").send_keys(" check this out!")
    click_on "send"

    using_session("David") do
      # David should see the message with his mention
      assert_message_text "check this out!"
    end
  end
end
