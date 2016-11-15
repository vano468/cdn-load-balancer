class Balancer::ServersInfo
  REQUEST_TIMEOUT = 2
  CACHING_PERIOD = 15.seconds

  attr_reader :urls, :info

  def initialize(urls:)
    @urls = urls
    @info = {}
  end

  def fetch
    urls.map { |u| fetch_single_server(u) }.map(&:join)
    info
  end

  private

  def fetch_single_server(url)
    wrap_thread_timeout do
      @info[url] = wrap_caching("servers_info/#{url}") do
        params = "salt=#{Figaro.env.nimble_streamer_salt}&hash=#{Figaro.env.nimble_streamer_hash}"
        uri = URI("http://#{url}:8082/manage/server_status?#{params}")
        res = Net::HTTP.get_response(uri)
        JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
      end
    end
  end

  def wrap_thread_timeout
    Thread.new do
      begin
        Timeout::timeout(REQUEST_TIMEOUT) { yield }
      rescue Timeout::Error
        false
      end
    end
  end

  def wrap_caching(key)
    Rails.env.test? ?
      yield : Rails.cache.fetch(key, expires_in: CACHING_PERIOD) { yield }
  end
end
