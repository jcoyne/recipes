class SessionsController < Devise::SessionsController
  def create
    headers['Access-Control-Allow-Origin'] = '*'
    respond_to do |format|
      format.html { super }
      format.json {
        warden.authenticate!(scope: resource_name, recall: "#{controller_path}#new")
        render status: 200, json: { message: "Success" }
      }
    end
  end

  def destroy
    super
  end
end
