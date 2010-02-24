class MerbMonkey::Main < MerbMonkey::Application
  provides :json

  UNAUTHORIZED = { :error => "You are not authorized for this action" }.to_json  

  def index
    render
  end
  
  def autocomplete
    MerbMonkey.autocomplete(self).to_json
  rescue => e
    json_error(e.message)
  end
  
  def init
    MerbMonkey.init_for_controller(self).to_json
  rescue => e
    json_error(e.message)
  end
  
  def list
    MerbMonkey.list(self).to_json
  rescue => e
    json_error(e.message)
  end

  def create
    MerbMonkey.create(self).to_json
  rescue => e
    json_error(e.message)
  end
  
  def update
    MerbMonkey.update(self).to_json
  rescue => e
    json_error(e.message)
  end

  def update_all
    MerbMonkey.update_all(self).to_json
  rescue => e
    json_error(e.message)
  end

  def delete
    MerbMonkey.delete(self).to_json
  rescue => e
    json_error(e.message)
  end

  def delete_all
    MerbMonkey.delete_all(self).to_json
  rescue => e
    json_error(e.message)
  end
  
  def excel
    MerbMonkey.excel(self)
  rescue => e
    json_error(e.message)
  end
  
  def upload
    MerbMonkey.upload(self).to_json
  rescue => e
    json_error(e.message)
  end
  
  private
  def model_name_and_class
    model_name = MerbMonkey.models.each { |name, model| break name if name == params[:model] }
    [model_name, MerbMonkey.const_get(model_name)]
  end
  
  def authorized_for(crud, model_name)
    test = MerbMonkey.models[model_name][crud]
    test.respond_to?(:call) ? test.call(self) == true : test == true
  end
  
  def json_error(msg)
    { :error => msg }.to_json.gsub("null", "\"\"")
  end
  
end
