module Operations
  class OrderLineItem::Read < Base
    def run
      model if allowed?
    end
  end
end
