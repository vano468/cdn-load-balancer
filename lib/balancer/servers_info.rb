class Balancer::ServersInfo
  REQUEST_TIMEOUT = 2

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
      uri = URI("http://#{url}:8082/manage/server_status?salt=501120&hash=MK4eLWVhz/3bTQbrD5bCdg==")
      res = Net::HTTP.get_response(uri)
      @info[url] = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
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
end
