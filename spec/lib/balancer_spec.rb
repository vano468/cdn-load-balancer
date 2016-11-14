require 'rails_helper'

describe Balancer do
  let(:country) { nil }
  let(:instance) { Balancer.new(ip: ip, current_country: country) }

  let(:ip) { '127.0.0.1' }
  let(:russia_ip) { '37.145.150.150' }
  let(:ukraine_ip) { '5.255.160.0' }

  let(:russian_servers) { %w(static-ru.ororo.tv) }
  let(:ukrainian_servers) { %w(static-ua2.ororo.tv) }
  let(:american_servers) { %w(static-ca2.ororo.tv) }
  let(:european_servers) { %w(static-de.ororo.tv static-uk.ororo.tv static-uk2.ororo.tv static-rbx.ororo.tv static-rbx2.ororo.tv static-fr.ororo.tv) }

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
      let(:country) { 'RU' }

      it { expect(european_servers).to include(subject) }
    end

    # expect host from europe
    context 'user from RU and RU server is overloaded',
      vcr: { cassette: 'resolve_host/ru_none_ru' } do

      let(:ip) { russia_ip }

      it { expect(european_servers).to include(subject) }
    end

    # expect host from ukraine / america
    context 'user from RU with RU server and ALL europe servers are overloaded',
      vcr: { cassette: 'resolve_host/ru_ru_eu' } do

      let(:ip) { russia_ip }
      let(:country) { 'RU' }

      it { expect(american_servers + ukrainian_servers).to include(subject) }
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
