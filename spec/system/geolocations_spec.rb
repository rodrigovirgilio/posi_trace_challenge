# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Swagger UI", type: :system do
  before do
    driven_by :headless_firefox
  end

  it "loads Swagger UI and displays the API documentation" do
    visit "/api-docs"

    expect(page).to have_css("#swagger-ui")
    expect(page).to have_text("PosiTrace Geolocation API V1")
  end

  it "shows the geolocations endpoints" do
    visit "/api-docs"

    # Swagger UI renders endpoints with line breaks between method and path
    expect(page).to have_text("POST")
    expect(page).to have_text("/api/v1/geolocations")
    expect(page).to have_text("GET")
    expect(page).to have_text("/api/v1/geolocations/{location}")
    expect(page).to have_text("DELETE")
  end
end