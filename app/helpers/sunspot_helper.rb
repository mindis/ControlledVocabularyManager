require 'rubygems'
require 'sunspot'

module SunspotHelper
  class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
    def id
      @instance.id  # return the book number as the id
    end
  end

  class DataAccessor < Sunspot::Adapters::DataAccessor
    def load( id )
      Term.find(id)
    end

    def load_all( ids )
      ids.map { |id| Term.find(id) }
    end
  end
end
