# frozen_string_literal: true

module ApplicationHelper
  FLASH_TAILWIND_CLASSES = {
    success: "bg-green-100 border-green-400 text-green-800",
    notice: "bg-blue-100 border-blue-400 text-blue-800",
    info: "bg-blue-100 border-blue-400 text-blue-800",
    primary: "bg-indigo-100 border-indigo-400 text-indigo-800",
    secondary: "bg-gray-100 border-gray-400 text-gray-800",
    warning: "bg-yellow-100 border-yellow-400 text-yellow-800",
    alert: "bg-red-100 border-red-400 text-red-800",
    error: "bg-red-100 border-red-400 text-red-800",
    danger: "bg-red-100 border-red-400 text-red-800"
  }.freeze

  FLASH_DEFAULT_CLASS = "bg-gray-100 border-gray-400 text-gray-800"

  def tailwind_class_for(flash_type)
    FLASH_TAILWIND_CLASSES.fetch(flash_type.to_sym, FLASH_DEFAULT_CLASS)
  end
end
