require 'spec_helper'

describe OrderOperations do

  context 'SendReceipt' do
    context 'run' do
      it 'is allowed' do
        attendance = create(:attendance)
        order = create(:order, attendance: attendance)

        operation = OrderOperations::SendReceipt.new(order.user, {id: order.id})
        allow(operation).to receive(:allowed?){ true }

        expect{
          operation.run
        }.to change(ActionMailer::Base.deliveries, :count).by 1
      end
    end
  end

end
