class Balancer
  # https://github.com/cjheath/geoip/blob/master/data/geoip/country_code.yml
  def self.servers
    { 'static-ca2.ororo.tv'  => { channel: 1000, countries: %w(CA US BR MX CO AR), ranking: { priority: 1, weight: 1 } },
      'static-ru.ororo.tv'   => { channel: 3000, countries: %w(RU BY KZ AM TR AZ), ranking: { priority: 1, weight: 1 } },
      'static-ua2.ororo.tv'  => { channel: 1000, countries: %w(UA), ranking: { priority: 1, weight: 1 } },
      'static-de.ororo.tv'   => { channel: 1000, countries: %w(DE), ranking: { priority: 2, weight: 2 } },
      'static-uk.ororo.tv'   => { channel: 1000, countries: %w(UK), ranking: { priority: 2, weight: 6 } },
      'static-uk2.ororo.tv'  => { channel: 1000, countries: %w(UK), ranking: { priority: 2, weight: 6 } },
      'static-rbx.ororo.tv'  => { channel: 2500, countries: %w(FR), ranking: { priority: 2, weight: 20 } },
      'static-rbx2.ororo.tv' => { channel: 2500, countries: %w(FR), ranking: { priority: 2, weight: 20 } },
      'static-fr.ororo.tv'   => { channel: 1000, countries: %w(FR), ranking: { priority: 2, weight: 4 } } }
  end

  attr_reader :ip, :current_server

  def initialize(ip:, current_server: nil)
    @ip = ip
    @current_server = current_server
    @servers = self.class.servers
  end

  def resolve_host
    reject_by_server(current_server) if current_server
    reject_by_overload
    select_by_ip_country || select_by_priority_group
  end

  private

  def reject_by_server(server)
    @servers.reject! { |url, _| server == url }
  end

  def reject_by_overload
    servers_info = ServersInfo.new(urls: @servers.keys).fetch
    @servers.reject! do |url, data|
      !servers_info[url] ||
        server_overload?(data[:channel], servers_info[url])
    end
  end

  def server_overload?(channel, server_info)
    load_in_mbps = server_info['OutRate'] / 1000 / 1000
    required_free = channel / 1000 * 100
    channel - required_free <= load_in_mbps
  end

  def select_by_ip_country
    max_mind = MaxMindDB.new("#{Rails.root.to_s}/db/GeoLite2-Country.mmdb").lookup(@ip)
    country = max_mind.country.iso_code # keep in mind that it may sometimes return "--"
    result = @servers.find { |_, data| (data[:countries] || []).include?(country) }
    result && result.first
  end

  def select_by_priority_group
    priority = highest_priority_group
    return nil if priority == 0

    randomizer_data = @servers.select do |_, data|
      data[:ranking][:priority] == priority
    end.each_with_object({}) do |(url, data), memo|
      memo[url] = data[:ranking][:weight]
    end
    WeightedRandomizer.new(randomizer_data).sample
  end

  def highest_priority_group
    @servers.inject(0) do |max, (_, data)|
      data[:ranking][:priority] > max ? data[:ranking][:priority] : max
    end
  end
end
