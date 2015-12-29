class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # TODO if we turn this on it's going to check the token. Currently our front-end isn't sending
  # the token 
  # acts_as_token_authentication_handler_for User
end
