# frozen_string_literal: true

module Api
  module Events
    module RegistrationOperations
      class Read < SkinnyControllers::Operation::Default
        include ::HelperOperations::EventManagementPermissionChecks

        def run
          model = event.registrations
                       .with_deleted
                       .includes(
                         :custom_field_responses,
                         :housing_request, :housing_provision,
                         orders: [
                           order_line_items: [
                             line_item: [:order_line_items]
                           ]
                         ]
                       ).find(params[:id])

          check_allowed!

          model
        end
      end
    end
  end
end
