require 'label_timing/version'
require 'label_timing/railtie'

module LabelTiming
  def self.on form
    form.instance_variable_set :@field_times, []
    form.instance_variable_set :@field_idx, -1

    class << form
      alias_method :o_label, :label
      attr_reader :field_times

      def label *args
        field_times << [(@field_idx += 1), args[0], Time.current]
        o_label *args
      end
    end
  end
end

module ActionView::Helpers::FormHelper

  alias_method :o_form_for, :form_for

  def form_for *args, &blk
    return o_form_for(*args, &blk) if params[:label_timing] == nil
    fb = nil
    form_fragment = o_form_for *args do |*form_builder|
      fb = form_builder[0]
      ::LabelTiming.on fb
      fb.label :start_label_timing
      blk[*form_builder]
      fb.label :end_label_timing
    end
    form_id = "lbt_#{args[1].try(:[], :html).try(:[], :id) || form_fragment.object_id}"
    (request.env['label_timing'] ||= {})[form_id] = {
      total: (fb.field_times[-1][2] - fb.field_times[0][2]),
      labels: fb.field_times
    }
    form_fragment
  end
end
