module Sucker

  # Stubs Sucker::Response to run specs offline. Ideally, I'd like to use
  # a general-purpose stubber for Curb but last time I checked, there was
  # none.
  class MockResponse < Response
    def initialize(mock_response_body)
      self.body = mock_response_body
      self.code = 200
      self.time = 0.1
    end
  end

  class << self
    attr_accessor :fixtures_path

    # Records a request on first run and fakes subsequently
    def stub(request)
      request.instance_eval do
        self.class.send :define_method, :fixture do
          values = parameters.
            reject { |k, v| %w{AWSAccessKeyId Service}.include? k }.
            values.
            flatten.
            join
          filename = Digest::MD5.hexdigest(host + values)
          "#{Sucker.fixtures_path}/#{filename}.xml"
        end

        self.class.send :define_method, :get do
          if File.exists?(fixture)
            MockResponse.new(File.new(fixture, "r").read)
          else
            curl.url = uri.to_s
            curl.perform
            response = Response.new(curl)

            File.open(fixture, "w") { |f| f.write response.body }

            response
          end
        end
      end
    end
  end
end
