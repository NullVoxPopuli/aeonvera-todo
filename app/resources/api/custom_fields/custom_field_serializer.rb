# frozen_string_literal: true
module Api
  class CustomFieldSerializer < ActiveModel::Serializer
    include PublicAttributes::CustomFieldAttributes

    has_many :custom_field_responses
  end
end
