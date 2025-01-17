module Api
  module OrderOperations
    class Pay < SkinnyControllers::Operation::Base
      # It is assumed that this operation is already authorized.
      # Therefor, it should not be invoked directly from a controller,
      # only another operation.
      def initialize(model, current_user, params, params_for_action)
        super(current_user, params, params_for_action)

        @model = model
      end

      def run
        pay

        model
      end

      private

      def pay
        original_paid_status = model.paid?

        update

        paid_changed = original_paid_status != model.paid?

        payment_succeeded = model.errors.blank? && paid_changed && model.paid?
        return unless payment_succeeded

        OrderMailer.receipt(for_order: model).deliver_now
      end

      def update
        payment_method = params_for_action[:payment_method]

        model.payment_method = payment_method

        if payment_method != Payable::Methods::STRIPE
          model.check_number = params_for_action[:check_number]

          model.paid                = true
          model.paid_amount         = params_for_action[:paid_amount]
          model.net_amount_received = model.paid_amount
          model.total_fee_amount    = 0
          model.save if model.errors.full_messages.empty?
        else
          # if this succeeds, the order will be saved
          update_stripe
        end

        # TODO: make async
        OrderOperations::CheckForMembership.new(model.id).call
      end

      def update_stripe
        # get the stripe credentials
        checkout_token, checkout_email = params_for_action.values_at(:checkout_token, :checkout_email)
        integration = model.host.integrations[Integration::STRIPE]
        access_token = integration.config['access_token']
        absorb_fees = !model.host.make_attendees_pay_fees?

        # hopefully this never happens... but we want specific errors
        # just in case
        check_required_information(checkout_token, integration, access_token)
        return if model.errors.present?

        # charge the card.
        # this will add errors to the model if something
        # goes wrong with the charge process
        # NOTE: if this succeeds, the order is saved
        StripeTasks::ChargeCard.charge_card!(
          checkout_token,
          checkout_email,
          absorb_fees: absorb_fees,
          secret_key: access_token,
          order: model
        )
      end

      def check_required_information(checkout_token, integration, access_token)
        unless checkout_token.present?
          model.errors.add(:base, 'No Stripe Checkout Information Found')
        end

        unless integration.present?
          model.errors.add(:base, 'No Stripe Integration Present')
        end

        unless access_token.present?
          model.errors.add(:base, 'No Stripe Access Token Present')
        end
      end
    end
  end
end
