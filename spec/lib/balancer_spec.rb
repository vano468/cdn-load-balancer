require 'rails_helper'

describe Balancer do
  let(:current_server) { nil }
  let(:instance) { Balancer.new(ip: ip, current_server: current_server) }

  let(:ip) { '127.0.0.1' }
  let(:russia_ip) { '37.145.150.150' }
  let(:ukraine_ip) { '5.255.160.0' }
  let(:france_ip) { '5.57.96.0' }

  let(:russian_servers) { %w(static-ru.ororo.tv) }
  let(:ukrainian_servers) { %w(static-ua2.ororo.tv) }
  let(:american_servers) { %w(static-ca2.ororo.tv) }
  let(:french_servers) { %w(static-rbx.ororo.tv static-rbx2.ororo.tv static-fr.ororo.tv) }
  let(:european_servers) { %w(static-de.ororo.tv static-uk.ororo.tv static-uk2.ororo.tv) + french_servers }

  describe '#resolve_host' do
    subject { instance.resolve_host }

    # expect host from ukraine
    context 'user from UA',
      vcr: { cassette: 'resolve_host/ua_none_none' } do

      let(:ip) { ukraine_ip }

      it { expect(ukrainian_servers).to include(subject) }
    end

    # expect host from europe
    context 'user from RU with RU server',
      vcr: { cassette: 'resolve_host/ru_ru_none' } do

      let(:ip) { russia_ip }
      let(:current_server) { russian_servers.first }

      it { expect(european_servers).to include(subject) }
    end

    # expect host from europe
    context 'user from RU and RU server is overloaded',
      vcr: { cassette: 'resolve_host/ru_none_ru' } do

      let(:ip) { russia_ip }

      it { expect(european_servers).to include(subject) }
    end

    # expect host from ukraine / america
    context 'user from RU with RU server and ALL EU servers are overloaded',
      vcr: { cassette: 'resolve_host/ru_ru_eu' } do

      let(:ip) { russia_ip }
      let(:current_server) { russian_servers.first }

      it { expect(american_servers + ukrainian_servers).to include(subject) }
    end

    # expect host from france
    context 'user from FR with FR server',
      vcr: { cassette: 'resolve_host/fr_fr_none' } do

      let(:ip) { france_ip }
      let(:current_server) { french_servers.first }

      it { expect(french_servers[1..-1]).to include(subject) }
    end

    # expect specific host from france
    context 'user from FR and MAJOR FR servers are overloaded',
      vcr: { cassette: 'resolve_host/fr_none_majorfr' } do

      let(:ip) { france_ip }

      it { is_expected.to eq(french_servers.last) }
    end

    # expect nil result
    context 'ALL servers are overloaded',
      vcr: { cassette: 'resolve_host/none_none_all' } do

      it { is_expected.to be_nil }
    end

    # expect nil result
    context 'ALL servers are unreachable',
      vcr: { cassette: 'resolve_host/none_none_allu' } do

      it { is_expected.to be_nil }
    end
  end
end
