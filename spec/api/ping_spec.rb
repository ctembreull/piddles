require 'spec_helper'

describe Piddles::API do

  def app
    Piddles::API
  end

  describe Piddles::Ping do
    it 'goes ping' do
      get '/ping'
      expect(last_response.status).to eq(200)
    end
  end
end
