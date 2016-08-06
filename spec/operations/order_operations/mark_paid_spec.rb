require 'spec_helper'

describe OrderOperations::MarkPaid do
  let(:klass){ OrderOperations::MarkPaid }
  let(:owner){ create_confirmed_user }
  let(:event){ create(:event, hosted_by: owner) }
  let(:attendance){ create(:attendance, host: event) }
  let(:package){ create(:package, event: event) }

  context 'order is paid' do
    it 'does not change any of the attributes' do
      order = create(:order,
        host: event, attendance: attendance,
        payment_method: "Boop",  paid: true)

      params = {
        id: order.id,
        payment_method: 'Cash'
      }

      result = klass.new(owner, params).run
      expect(result.payment_method).to_not eq 'Cash'
    end
  end

  context 'order is unpaid' do
    it 'marks an order as paid' do
      order = create(:order, host: event, attendance: attendance)
      add_to_order(order, package)

      params = {
        id: order.id,
        payment_method: 'Cash'
      }

      result = klass.new(owner, params, params[:order]).run
      expect(result.paid).to eq true
    end

    it 'marks an order as paid with a total of 0' do
      order = create(:order, host: event, attendance: attendance)
      add_to_order(order, package)

      params = {
        id: order.id,
        payment_method: 'Cash',
        amount: 0
      }

      result = klass.new(owner, params).run
      expect(result.paid).to eq true
    end

    it 'updates the payment_method' do
      order = create(:order, host: event, attendance: attendance, payment_method: "Boop")
      add_to_order!(order, package)
      expect(order.paid).to eq false

      params = {
        id: order.id,
        payment_method: 'Cash'
      }

      result = klass.new(owner, params).run
      expect(result.payment_method).to eq 'Cash'
    end

    it 'sets the check_number' do
      order = create(:order, host: event, attendance: attendance)
      add_to_order!(order, package)
      expect(order.paid).to eq false

      params = {
        id: order.id,
        payment_method: 'Check',
        check_number: '1234'
      }

      result = klass.new(owner, params).run
      expect(result.check_number).to eq '1234'
    end

    it 'marks an order as paid with persistence' do
      order = create(:order, host: event, attendance: attendance)

      params = {
        id: order.id,
        payment_method: 'Cash'
      }

      result = klass.new(owner, params).run
      result.reload
      expect(result.paid).to eq true
    end
  end
end
