module Vario
  class SettingsController < ApplicationController
    def index
      @settings = Setting.all
    end

    def show
      @setting = Setting.find(params[:id])
    end
  end
end
