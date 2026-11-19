class ApplicationController < ActionController::Base
  # The account last shown is the current one, whose settings vario's pages show
  before_action { Current.account = Account.find_by(id: session[:account_id]) }
end
