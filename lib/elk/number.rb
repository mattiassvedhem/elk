module Elk
  # Allocate and manage numbers used for SMS/MMS/Voice
  class Number
    attr_reader :number_id, :number, :capabilities, :loaded_at #:nodoc:
    attr_accessor :country, :sms_url, :voice_start_url #:nodoc:

    def initialize(parameters) #:nodoc:
      set_paramaters(parameters)
    end

    def set_paramaters(parameters) #:nodoc:
      @country      = parameters[:country]
      @sms_url      = parameters[:sms_url]
      @voice_start_url = parameters[:voice_start_url]
      @status       = parameters[:active]
      @number_id    = parameters[:id]
      @number       = parameters[:number]
      @capabilities = parameters[:capabilities].collect {|c| c.to_sym }
      @loaded_at    = Time.now
    end

    # Status of a number, if it's :active or :deallocated
    def status
      case @status
      when 'yes'
        :active
      when 'no'
        :deallocated
      else
        nil
      end
    end

    # Reloads a number from the API server
    def reload
      response = Elk.get("/Numbers/#{self.number_id}")
      self.set_paramaters(Elk.parse_json(response.body))
      response.code == 200
    end

    # Updates or allocates a number
    def save
      attributes = {:sms_url => self.sms_url, :voice_start => self.voice_start_url}
      # If new URL, send country, otherwise not
      if !self.number_id
        attributes[:country] = self.country
      end
      response = Elk.post("/Numbers/#{self.number_id}", attributes)
      response.code == 200
    end

    # Deallocates a number, once allocated, a number cannot be used again, ever!
    def deallocate!
      response = Elk.post("/Numbers/#{self.number_id}", {:active => 'no'})
      self.set_paramaters(Elk.parse_json(response.body))
      response.code == 200
    end

    class << self
      include Elk::Util

      # Allocates a phone number
      #
      # * Required parameters: :country
      # * Optional parameters: :sms_url, :voice_start_url
      def allocate(parameters)
        verify_parameters(parameters, [:country])
        response = Elk.post('/Numbers', parameters)
        self.new(Elk.parse_json(response.body))
      end

      # Returns all Elk::Numbers, regardless of status (allocated/deallocated)
      def all
        response = Elk.get('/Numbers')

        Elk.parse_json(response.body)[:data].collect do |n|
          self.new(n)
        end
      end
    end
  end
end
