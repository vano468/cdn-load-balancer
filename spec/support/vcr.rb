VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!

  c.before_record do |i|
    i.response.headers.delete('Set-Cookie')
    i.request.headers.delete('Authorization')
  end
end

RSpec.configure do |config|
  config.around(:each) do |example|
    options = example.metadata[:vcr]
    if !options
      example.call
    elsif options[:record] == :skip
      VCR.turned_off(&example)
    else
      cassette = if options[:strip_classname]
        options[:cassette]
      else
        klass = example.metadata[:described_class]
        "#{klass.to_s.underscore}/#{options[:cassette]}"
      end
      example.metadata[:vcr] = { cassette_name: cassette }
      example.call
    end
  end
end
