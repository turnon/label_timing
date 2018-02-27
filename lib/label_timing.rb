require "label_timing/version"

module LabelTiming
  def self.on form
    form.instance_variable_set :@field_times, []

    class << form
      alias_method :o_label, :label
      attr_reader :field_times

      def label *args
        field_times << [args[0], Time.current]
        o_label *args
      end

      def stastics_result
        @stastics_result ||= (
          field_times.each_with_index do |ft, i|
            if (nex_ft = field_times[i+1])
              ft << (nex_ft[1] - ft[1])
            else
              ft << 0
            end
          end
          {
            total: field_times[-1][1] - field_times[0][1],
            labels: field_times.sort_by{ |e| e[2] }
          }
        )
      end
    end
  end
end

module ActionView::Helpers::FormHelper

  alias_method :o_form_for, :form_for

  def form_for *args, &blk
    fb = nil
    form_fragment = o_form_for *args do |*form_builder|
      fb = form_builder[0]
      ::LabelTiming.on fb
      blk[*form_builder]
    end
    form_id = args[1].try(:[], :html).try(:[], :id) || "f_#{form_fragment.object_id}"
    form_fragment + raw("<script>var #{form_id} = #{fb.stastics_result.to_json};</script>")
  end
end
