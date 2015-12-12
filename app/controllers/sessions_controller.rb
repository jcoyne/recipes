class SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token

  def create
    headers['Access-Control-Allow-Origin'] = '*'
    respond_to do |format|
      format.html { super }
      format.json {
        warden.authenticate!(scope: resource_name, recall: "#{controller_path}#new")
        render status: 200, json: { token: current_user.authentication_token, email: current_user.email }
      }
    end
  end

  def destroy
    super
  end
end
