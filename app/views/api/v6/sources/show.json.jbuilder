json.meta do
  json.status "ok"
  json.set! :"message-type", "source"
  json.set! :"message-version", "6.0.1"
end

json.source do
  json.cache! ['v6', @source], skip_digest: true do
    json.(@source, :id, :title, :group_id, :description, :state, :timestamp)
    if @source.group.name != "other"
      json.(@source, :work_count, :relation_count, :event_count, :by_month)
    end
  end
end
