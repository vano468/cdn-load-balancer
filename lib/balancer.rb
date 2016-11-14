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

  attr_reader :ip, :current_country

  def initialize(ip:, current_country: nil)
    @ip = ip
    @current_country = current_country
    @servers = self.class.servers
  end

  def resolve_host
    reject_by_country(current_country) if current_country
    reject_by_overload
  end

  private

  def reject_by_country(country)
    @servers.reject! { |_, v| (v[:countries] || []).include?(country) }
  end

  def reject_by_overload
    
  end
end
