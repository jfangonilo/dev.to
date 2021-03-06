require "rails_helper"

RSpec.describe "Creating Comment", type: :system, js: true, vcr: true do
  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  # the article should be created before signing in
  let!(:article) { create(:article, user_id: user.id, show_comments: true) }
  let(:start_time) { VCR.current_cassette&.originally_recorded_at || Time.current }

  before do
    sign_in user
    $REDIS.flushall
    Timecop.travel(start_time)
  end

  it "User fills out comment box normally" do
    visit article.path.to_s

    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  it "User fill out comment box then click previews and submit" do
    visit article.path.to_s

    wait_for_javascript

    fill_in "text-area", with: raw_comment
    click_button("PREVIEW")
    expect(page).to have_text(raw_comment)
    expect(page).to have_text("MARKDOWN")
    click_button("MARKDOWN")
    expect(page).to have_text("PREVIEW")
    click_button("SUBMIT")
    expect(page).to have_text(raw_comment)
  end

  it "User replies to a comment" do
    create(:comment, commentable: article, user_id: user.id)
    visit article.path.to_s

    wait_for_javascript

    find(".toggle-reply-form").click
    find(:xpath, "//div[@class='actions']/form[@class='new_comment']/textarea").set(raw_comment)
    find(:xpath, "//div[contains(@class, 'reply-actions')]/input[@name='commit']").click
    expect(page).to have_text(raw_comment)
  end
end
