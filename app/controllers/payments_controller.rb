# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class PaymentsController < ApplicationController
  before_filter :check_authorization!
  # GET /payments
  # GET /payments.xml
  #def index
  #  @payments = Payment.org.all

  #  respond_to do |format|
  #    format.html # index.html.erb
  #    format.xml  { render :xml => @payments }
  #  end
  #end

  # GET /payments/1
  # GET /payments/1.xml
  #def show

  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.xml  { render :xml => @payment }
  #  end
  #end

  # GET /payments/new
  # GET /payments/new.xml
  def new
    @transaction = Transaction.org.find( params[:id] )
    @account_ledger = @transaction.new_payment
  end


  # POST /payments
  # POST /payments.xml
  def create
    @transaction = Transaction.org.find(params[:account_ledger][:transaction_id])

    # When it is the contact account
    if params[:account_ledger][:account_id] =~ /^\d+-\d+$/
      ac_id, cur_id = params[:account_ledger][:account_id].split("-")
      params[:account_ledger][:account_id] = ac_id
      params[:account_ledger][:currency_id] = cur_id
    end
    params[:account_ledger][:exchange_rate] = 1 if params[:account_ledger][:exchange_rate].blank?
    
    @account_ledger = @transaction.new_payment(params[:account_ledger])

    if @transaction.save_payment
      render 'create'
    else
      render 'new'
    end
  end

  # DELETE /payments/:id
  #def destroy
  #  @payment.destroy_payment
  #end

end
