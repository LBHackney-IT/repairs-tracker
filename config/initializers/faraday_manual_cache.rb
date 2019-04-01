API_REQUEST_CACHE = ActiveSupport::Cache::MemoryStore.new

FaradayManualCache.configure do |config|
  config.memory_store = API_REQUEST_CACHE
end
