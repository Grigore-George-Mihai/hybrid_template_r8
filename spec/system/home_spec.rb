# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home page", bullet: false, type: :system do
  let(:user) { create(:user, role: :admin) }

  before { sign_in user }

  it "renders the landing with the feature grid" do
    visit root_path

    expect(page).to have_content("Everything included")
    expect(page).to have_content("Authentication")
    expect(page).to have_content("Background Jobs")
  end

  it "only keeps one dropdown open at a time" do
    visit root_path
    find("summary", text: "Admin").click
    find("summary", text: "Account").click

    expect(page).to have_link("Profile")
    expect(page).to have_link("Swagger", visible: :hidden)
  end

  it "closes the open dropdown when clicking outside" do
    visit root_path

    find("summary", text: "Account").click
    expect(page).to have_link("Profile")

    find("h1", text: "Everything included").click
    expect(page).to have_link("Profile", visible: :hidden)
  end
end
