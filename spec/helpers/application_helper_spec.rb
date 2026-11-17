# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#tailwind_class_for" do
    {
      success: "bg-green-100",
      notice: "bg-blue-100",
      alert: "bg-red-100",
      error: "bg-red-100",
      warning: "bg-yellow-100",
      info: "bg-blue-100",
      primary: "bg-indigo-100",
      secondary: "bg-gray-100",
      danger: "bg-red-100",
      unknown: "bg-gray-100"
    }.each do |flash_type, expected_prefix|
      it "returns a class string starting with '#{expected_prefix}' for :#{flash_type}" do
        expect(helper.tailwind_class_for(flash_type)).to include(expected_prefix)
      end
    end
  end

  describe "#flash_duration_for" do
    before { allow(Rails.configuration.x).to receive(:flash_duration).and_return(nil) }

    it "keeps problem flashes up longer" do
      expect(helper.flash_duration_for("alert")).to eq(6000)
      expect(helper.flash_duration_for(:notice)).to eq(3000)
    end

    it "uses config.x.flash_duration when set" do
      allow(Rails.configuration.x).to receive(:flash_duration).and_return(60_000)
      expect(helper.flash_duration_for(:notice)).to eq(60_000)
    end
  end
end
