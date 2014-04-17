# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class Movements::Form < BaseForm
  attribute :id, Integer
  attribute :date, Date
  attribute :due_date, Date
  attribute :contact_id, Integer
  attribute :currency, String
  attribute :exchange_rate, Decimal, default: 1
  attribute :project_id, Integer
  attribute :description, String
  attribute :direct_payment, Boolean, default: false
  attribute :account_to_id, Integer
  attribute :reference, String
  attribute :tax_id, Integer
  attribute :tax_in_out, Boolean, default: false # true = out, false = in

  ATTRIBUTES = [:date, :contact_id, :currency, :exchange_rate, :project_id, :due_date,
                :description, :direct_payment, :account_to_id, :reference].freeze

  attr_accessor :service, :movement, :history

  validates_presence_of :movement
  validates_numericality_of :total
  validate :unique_item_ids

  delegate :ref_number, to: :movement
  delegate :ledger, to: :service

  def create
    set_errors(movement)  unless res = service.create(self)
    res
  end

  def create_and_approve
    set_errors(movement, ledger)  unless res = service.create_and_approve(self)
    res
  end

  def update(attrs = {})
    self.attributes = attrs
    set_errors(movement, ledger)  unless res = service.update(self)
    res
  end

  def update_and_approve(attrs = {})
    self.attributes = attrs
    set_errors(movement, ledger)  unless res = service.update_and_approve(self)
    res
  end

  def attr_details
    @attr_details || {}
  end

  def set_defaults
    self.date ||= Date.today
    self.due_date ||= Date.today
    self.currency ||= OrganisationSession.currency
  end

  def form_details_data
    details.map { |v|
      {
        id: v.id, item: v.item_to_s, item_id: v.item_id, price: v.price, quantity:
        v.quantity, original_price: v.item_price, errors: v.errors
      }
    }
  end

  def get_movement_attributes
    movement.attributes
  end

  private

    def unique_item_ids
      UniqueItem.new(self).valid?
    end

end
