# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
require File.dirname(__FILE__) + '/acceptance_helper'

#expect { t2.save }.to raise_error(ActiveRecord::StaleObjectError)

feature "Income", "test features" do
  background do
    #create_organisation_session
    OrganisationSession.set(:id => 1, :name => 'ecuanime', :currency_id => 1)
    create_user_session
  end

  let!(:organisation) { create_organisation(:id => 1) }
  let!(:items) { create_items }
  let(:item_ids) {Item.org.map(&:id)}
  let!(:bank) { create_bank(:number => '123', :amount => 0) }
  let(:bank_account) { bank.account }
  let!(:client) { create_client(:matchcode => 'Karina Luna') }
  let!(:tax) { Tax.create(:name => "Tax1", :abbreviation => "ta", :rate => 10)}

  let(:income_params) do
      d = Date.today
      i_params = {"active"=>nil, "bill_number"=>"56498797", "contact_id" => client.id, 
        "exchange_rate"=>1, "currency_id"=>1, "date"=>d, 
        "description"=>"Esto es una prueba", "discount" => 0, "project_id"=>1 
      }

      details = [
        { "description"=>"jejeje", "item_id"=>1, "price"=>3, "quantity"=> 10},
        { "description"=>"jejeje", "item_id"=>2, "price"=>5, "quantity"=> 20}
      ]
      i_params[:transaction_details_attributes] = details
      i_params
  end

  let(:pay_plan_params) do
    d = options[:payment_date] || Date.today
    {:alert_date => (d - 5.days), :payment_date => d,
     :ctype => 'Income', :description => 'Prueba de vida!', 
     :email => true }.merge(options)
  end

  scenario "Edit a income and save history" do
    i = Income.new(income_params)
    i.save_trans.should be_true

    i.balance.should == 3 * 10 + 5 * 20
    i.total.should == i.balance
    i.should be_draft
    i.transaction_histories.should be_empty
    i.modified_by.should == UserSession.user_id

    # Approve de income
    i.approve!.should be_true
    i.should_not be_draft
    i.should be_approved

    i = Income.find(i.id)
    #p = i.new_payment(:account_id => bank_account.id, :base_amount => i.balance, :exchange_rate => 1, :reference => 'Cheque 143234', :operation => 'out')
    #i.save_payment
    #i.reload

    #p.should be_persisted
    #i.balance.should == 0
    #p.conciliate_account.should be_true
    #
    #bank_account.reload
    #bank_account.amount.should == p.amount
    ## Diminish the quantity in edit and the amount should go to the client account
    #i = Income.find(i.id)
    edit_params = income_params.dup
    edit_params[:transaction_details_attributes][0][:id] = i.transaction_details[0].id

    edit_params[:transaction_details_attributes][1][:id] = i.transaction_details[1].id
    edit_params[:transaction_details_attributes][1][:quantity] = 5
    edit_params[:transaction_details_attributes][1][:price] = 5.5
    i.attributes = edit_params
    i.save_trans.should be_true
    i.reload
    
    i.transaction_histories.should_not be_empty
    hist = i.transaction_histories.first
    hist.user_id.should == i.modified_by

    i.transaction_details[1].quantity.should == 5
    i.balance.should == 3 * 10 + 5 * 5.5

    hist.data[:transaction_details][0][:quantity].should == 10
    hist.data[:transaction_details][1][:quantity].should == 20
    hist.data[:transaction_details][1][:price].should == 5

    i.transaction_details[1].price.should == 5.5
  end


  scenario "Edit a income, pay and check that the client has the amount, and check states" do
    i = Income.new(income_params)
    i.save_trans.should be_true

    i.balance.should == 3 * 10 + 5 * 20
    bal = i.balance

    i.total.should == i.balance
    i.should be_draft
    i.transaction_histories.should be_empty
    i.modified_by.should == UserSession.user_id

    # Approve de income
    i.approve!.should be_true
    i.should_not be_draft
    i.should be_approved


    i = Income.find(i.id)
    p = i.new_payment(:account_id => bank_account.id, :base_amount => i.balance, :exchange_rate => 1, :reference => 'Cheque 143234', :operation => 'out')
    i.save_payment
    i.reload

    i.should_not be_deliver
    i.should be_paid
    p.should be_persisted
    i.balance.should == 0
    puts "-"*90
    p.transaction_id.should == i.id
    p.conciliate_account.should be_true
    
    bank_account.reload
    bank_account.amount.should == p.amount
    # Diminish the quantity in edit and the amount should go to the client account
    i = Income.find(i.id)

    i.account_ledgers.pendent.should be_empty
    i.balance.should == 0
    i.should be_deliver

    edit_params = income_params.dup
    edit_params[:transaction_details_attributes][0][:id] = i.transaction_details[0].id

    edit_params[:transaction_details_attributes][1][:id] = i.transaction_details[1].id
    edit_params[:transaction_details_attributes][1][:quantity] = 5
    i.attributes = edit_params
    i.save_trans.should be_true
    i.reload
    
    i.should be_paid
    i.balance.should == 0
    i.transaction_histories.should_not be_empty
    hist = i.transaction_histories.first
    hist.user_id.should == i.modified_by

    i.transaction_details[1].quantity.should == 5
    i.total.should == 3 * 10 + 5 * 5
    i.balance.should == 0

    ac = client.account_cur(i.currency_id)
    ac.amount.should == -(bal - i.balance)

    # Edit and change the amount so the state changes
    i = Income.find(i.id)
    edit_params = income_params.dup
    edit_params[:transaction_details_attributes][0][:id] = i.transaction_details[0].id

    edit_params[:transaction_details_attributes][1][:id] = i.transaction_details[1].id
    edit_params[:transaction_details_attributes][1][:quantity] = 5.1

    i.attributes = edit_params
    i.save_trans.should be_true
    i.reload

    i.should be_approved
    i.should_not be_deliver
    i.total.should ==  3 * 10 + 5 * 5.1
    i.balance.should ==  5 * 0.1

    # Change to  paid when changed again with the price
    i = Income.find(i.id)
    edit_params = income_params.dup
    edit_params[:transaction_details_attributes][0][:id] = i.transaction_details[0].id

    edit_params[:transaction_details_attributes][1][:id] = i.transaction_details[1].id
    edit_params[:transaction_details_attributes][1][:quantity] = 5

    i.attributes = edit_params
    i.save_trans.should be_true
    i.reload

    i.should be_paid
    i.total.should ==  3 * 10 + 5 * 5
    i.balance.should ==  0
  end

  scenario "check the number of items" do
    i = Income.new(income_params)
    i.save_trans.should be_true

    i.balance.should == 3 * 10 + 5 * 20
    bal = i.balance

    i.total.should == i.balance
    i.should be_draft
    i.transaction_histories.should be_empty
    i.modified_by.should == UserSession.user_id

    # Approve de income
    i.approve!.should be_true
    i.should_not be_draft
    i.should be_approved


    i = Income.find(i.id)
    p = i.new_payment(:account_id => bank_account.id, :base_amount => i.balance, :exchange_rate => 1, :reference => 'Cheque 143234', :operation => 'out')
    i.save_payment
    i.reload

    i.should be_paid
    p.should be_persisted
    i.balance.should == 0
    p.conciliate_account.should be_true
    
    p.should be_conciliation

  end
end