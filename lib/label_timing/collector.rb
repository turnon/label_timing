module LabelTiming
  class Collector
    def initialize app, config = nil
      @app = app
    end

    def call env
      resp = @app.call env
      return resp if env['label_timing'].nil?
      status, header, body = resp
      result = stastics env.delete 'label_timing'
      script = "<script>var lbt = #{result.to_json}</script>"
      inject_profile! body, script
      resp
    end

    private

    def stastics label_timing
      all_total = label_timing.inject(0){ |sum, h| sum + h[1][:total] }
      label_timing.each_with_object({all_total: all_total}) do |h, result|
        id, total, field_times = h[0], h[1][:total], h[1][:labels]
        enhance_time_log! all_total, total, field_times
        result[id] = {
          total: total,
          per: (all_total > 0 ? (total / all_total * 100).round(2) : 0),
          labels: field_times}
      end
    end

    def inject_profile! body, script
      if String == body
        _inject_profile! body, script
      else
        body.each{ |fragment| _inject_profile! fragment, script }
      end
    end

    def _inject_profile! fragment, script
      if (index = fragment.rindex(/<\/body>/i) || fragment.rindex(/<\/html>/i))
        fragment.insert(index, script)
      end
    end

    def enhance_time_log! all_total, total, field_times
      field_times.each_with_index do |ft, i|
        if (nex_ft = field_times[i+1])
          dur = (nex_ft[2] - ft[2])
          ft << dur
          ft << (total > 0 ? (dur / total * 100).round(2) : 0)
          ft << (all_total > 0 ? (dur / all_total * 100).round(2) : 0)
        else
          ft << 0 << 0 << 0
        end
      end.sort_by!{ |e| e[3] }
    end
  end
end
