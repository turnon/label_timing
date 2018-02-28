require 'label_timing/collector'

module LabelTiming
  class Railtie < ::Rails::Railtie
    initializer "label_timing.configure_rails_initialization" do |app|
      app.middleware.use LabelTiming::Collector
    end
  end
end
