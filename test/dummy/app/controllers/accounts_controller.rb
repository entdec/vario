class AccountsController < ApplicationController
  def new
    @account = Account.new
  end
  def create
    @account = Account.create(name: params[:account][:name])
    redirect_to action: :index
  end
  def index
  end
end