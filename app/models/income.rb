# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class Income < Transaction
  acts_as_org

  STATES = ["draf", "credit", "cash"]

  attr_accessible :ref_number, :date, :contact_id,
                  :project_id, :currency_id,
                  :discount, :bill_number, :taxis_ids,
                  :description, :transaction_details_attributes


  #accepts_nested_attributes_for :transaction_details, :allow_destroy => true
  #validations
  validates_presence_of :ref_number, :date

end
