class Order < ActiveRecord::Base
  include HasMetadata
  include StripePaymentHandler
  include Payable
  include OrderMembership

  belongs_to :host, polymorphic: true

	belongs_to :event, class_name: Event.name,
	 foreign_key: "host_id", foreign_type: "host_type", polymorphic: true


  belongs_to :attendance
  belongs_to :user

  has_many :line_items,
    class_name: "OrderLineItem",
    dependent: :destroy

  scope :unpaid, -> { where(paid: false) }
  scope :paid, -> {where(paid: true)}
  scope :created_after, ->(time){ where("orders.created_at > ?", time) }
  scope :created_before, ->(time){ where("orders.created_at < ?", time) }

  after_save do |instance|
    instance.process_membership
    instance.apply_membership_discount
    true
  end

  before_save do |instance|
    instance.check_paid_status
    true
    # before filter must return true to continue saving.
    # the above two checks do not halt saving, nor do they
    # create a bad state
  end

  # DEPRECATED: Was for use with PayPal's API
  def set_payment_token(token)
    self.payment_token = token
    self.save
  end

  # short hand for setting a field on the metadata
  def set_payment_details(details)
    self.metadata[:details] = details
  end

  def force_paid!
    self.paid = true
    self.save
  end

  def owes
    paid? ? 0 : total
  end

  def save_payment_errors(errors)
    self.metadata[:errors] = errors
    self.save
  end

  def self.paypal_fees(orders)
    (orders.count * (0.3)) + orders.map{|o|
      o.total * 0.029
    }.inject(:+).to_f
  end


  # ideally, this is ran upon successful payment
  def set_net_amount_received_and_fees

    if self.payment_method == Payable::Methods::STRIPE
      set_net_amount_received_and_fees_from_stripe
    end
  end


  def check_paid_status
    # if we don't owe anything
    # - can happen on new record
    # - can happen if paid
    if self.total == 0.0
      # set to paid
      self.payer_id = "0"
      self.paid = true

      # if the paid amount is /still/ nil
      if self.paid_amount == nil
        # set the paid amount to 0.0, since the total is 0.0
        self.paid_amount = 0.0
      end

    elsif self.paid_amount.nil?
      # money is owed, the order has not been paid
      self.paid = false
    end


    if self.paid == true && paid_amount == nil && self.total == 0.0
      self.paid = false
    end
  end


  def belongs_to_organization?
    host_type == Organization.name
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["Name", "Email", "Registered At", "Payment Method", "Paid",
        "Total Fees", "Net Received", "Line Items"]
      all.each do |order|

        order_user = order.user

        line_item_list = order.line_items.map do |i|
          "#{i.quantity} x #{i.name} @ #{i.price}"
        end.join(", ")

        row = [
            order_user.try(:name) || "Unknown",
            order_user.try(:email) || "Unknown",
            order.created_at,
            order.payment_method,
            order.paid_amount,
            order.total_fee_amount,
            order.net_amount_received,
            line_item_list
        ]
        csv << row
      end
    end
  end

end
