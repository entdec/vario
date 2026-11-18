class AccountsController < ApplicationController
  def new
    @account = Account.new
  end
  def create
    @account = Account.create(name: params[:account][:name])
    redirect_to action: :index
  end
  def show
    @account = Account.find(params[:id])
  end
  def index
    @accounts = Account.order(:name)
  end
end