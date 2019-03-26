class PagesController < ApplicationController
  before_action :authenticate

  def home
  end

  protected

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "admin" && password == "celiathebest"
    end
  end

end
