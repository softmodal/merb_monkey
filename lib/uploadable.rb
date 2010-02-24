module Uploadable
  def upload(path, cache=true)
    # remove 'errors' field in case we're re-uploading
    data = file_to_array(path).map { |item| item.except(:errors) }
    check_headers(data)
    batch_insert(data, cache)
  end
 
  def check_headers(data)
    obj = self.new
    keys = data.map { |datum| datum.keys }.flatten.uniq
    errors = []
    keys.each do |key|
      obj.respond_to?(key.to_s + "=") || errors.push(key)
    end
    unless errors.empty?
      err_txt = "'#{errors.join("', '")}'"
      attr_txt = (errors.size > 1) ? "attributes" : "attribute"
      raise(ArgumentError, "#{self} has no #{attr_txt}: #{err_txt}")
    end
  end
 
  def batch_insert(data, cache=true)
    data = cache(data) if cache
    errors = []
    save_method = self.new.respond_to?(:save_without_before_filter) ? :save_without_before_filter : :save
    data.each_with_index do |row, i|
      obj = if row.keys.include?(:id) and row[:id].to_i > 0
        o = self.get(row[:id])
        if o.nil?
          errors.push(row.merge(:errors => "No #{self.name.snake_case.gsub("_", " ")} was found with this id"))
          next
        end
        #update the attributes, but don't save yet
        row.except(:id).each { |key, val| o.send(key.to_s + "=", val) }
        o
      else
        self.new(row)
      end
      unless obj.send(save_method)
        #errors.push(obj.errors.map { |e| e.to_s }.join(" and "))
        errors.push(row.merge(:errors => obj.errors.map { |e| e.to_s }.join(" and ")))
      end
    end
    #errors.uniq.map { |e| {:message => e} }
    errors
  end
  
  def file_to_array(path)
    extension = File.extname(path)
    case extension
    when ".csv"
      _delimited_file_to_array(path, ",")
    when ".psv"
      _delimited_file_to_array(path)
    when ".xls"
      ExcelLoader::file_to_array(path)
    else
      raise ArgumentError, "File type not supported: #{extension}"
    end
  end
  
  def associations_to_cache
    {}
  end
  
  def cache(data)
    associations = self.associations_to_cache
    return data if associations == {}
    keys = associations.keys.map { |k| k.to_s }
    _cache = {}
    keys.each { |key| _cache[key] = { :new_key => associations[key.intern], :data => {} } }
    
    obj = self.new
    data.each do |row|
      row.each_pair do |key, value|
        if keys.include?(key)
          _cache_key = _cache[key.to_s]
          # We check the _cache and change the data if it's already been looked up
          new_val = _cache_key[:data][value]
          # If it hasn't, we look it up and save it in the _cache
          unless new_val
            setter = "#{key}="
            if obj.respond_to?(setter)
              obj.send(setter, value)
              new_val = obj.send(_cache_key[:new_key])
              _cache_key[:data][value] = new_val
            end
          end
          # Now we remove the old key/value in the row and replace it
          row.delete(key)
          row[_cache_key[:new_key]] = new_val
        end
      end
    end
    data
  end
  
  private
  def _delimited_file_to_array(path, delimiter="|")
    header_line = true
    headers = []
    data = []
    File.new(path).each do |line|
      if header_line
        headers = line.split(delimiter).map { |h| h.strip }
        header_line = false
      else
        vals = line.split(delimiter)
        datum = {}
        headers.each_with_index { |h, i| datum[h] = vals[i].strip }
        data.push(datum)
      end
    end
    data
  end
end