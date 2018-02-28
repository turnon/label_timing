require "label_timing/version"

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

      def stastics_result
        @stastics_result ||= (
          if field_times.size > 0
            enhance_time_log!
            {total: @total, labels: field_times}
          else
            {total: nil, labels: nil}
          end
        )
      end

      def enhance_time_log!
        @total = field_times[-1][2] - field_times[0][2]
        field_times.each_with_index do |ft, i|
          if (nex_ft = field_times[i+1])
            dur = (nex_ft[2] - ft[2])
            ft << dur
            ft << (@total > 0 ? (dur / @total * 100).round(2) : 0)
          else
            ft << 0 << 0
          end
        end.sort_by!{ |e| e[3] }
      end

      def js_stastics_result id
        "<script>
           var #{id} = #{stastics_result.to_json};
           #{id}.order = function(n){
             if(n !== 1 && n !== 2){
               return this.labels.sort(function(a, b){
                 return a[n] - b[n];
               });
             }
             return this.labels.sort(function(a, b){
               if(!/^[a-zA-Z0-9]/.test(a[n]) && !/^[a-zA-Z0-9]/.test(b[n])){
                 return a[n].localeCompare(b[n], 'zh');
               }
               return a[n] > b[n] ? 1 : -1;
             });
           };
         </script>".gsub(/\n\s*/, '')
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
    form_fragment + raw(fb.js_stastics_result(form_id))
  end
end
