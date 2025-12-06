# frozen_string_literal: true

module Mui
  class LineRenderer
    def initialize(color_scheme)
      @color_scheme = color_scheme
      @highlighters = []
    end

    def add_highlighter(highlighter)
      @highlighters << highlighter
    end

    def render(screen, line, row, x, y, options = {})
      highlights = collect_highlights(row, line, options)
      render_with_highlights(screen, line, x, y, highlights)
    end

    private

    def collect_highlights(row, line, options)
      @highlighters
        .flat_map { |h| h.highlights_for(row, line, options) }
        .sort
    end

    def render_with_highlights(screen, line, x, y, highlights)
      if highlights.empty?
        put_text(screen, y, x, line, :normal)
        return
      end

      segments = build_segments(line, highlights)
      current_x = x

      segments.each do |segment|
        put_text(screen, y, current_x, segment[:text], segment[:style])
        current_x += segment[:text].length
      end
    end

    def build_segments(line, highlights)
      segments = []
      current_pos = 0
      active_highlights = []

      events = build_events(highlights, line.length)

      events.each do |event|
        if event[:pos] > current_pos && current_pos < line.length
          end_pos = [event[:pos], line.length].min
          style = active_highlights.max_by(&:priority)&.style || :normal
          text = line[current_pos...end_pos]
          segments << { text:, style: } unless text.empty?
          current_pos = end_pos
        end

        case event[:type]
        when :start
          active_highlights << event[:highlight]
        when :end
          active_highlights.delete(event[:highlight])
        end
      end

      if current_pos < line.length
        style = active_highlights.max_by(&:priority)&.style || :normal
        segments << { text: line[current_pos..], style: }
      end

      segments
    end

    def build_events(highlights, line_length)
      events = []
      highlights.each do |h|
        start_col = [h.start_col, 0].max
        end_col = [h.end_col, line_length - 1].min
        next if start_col > end_col

        events << { pos: start_col, type: :start, highlight: h }
        events << { pos: end_col + 1, type: :end, highlight: h }
      end
      events.sort_by! { |e| [e[:pos], e[:type] == :end ? 0 : 1] }
      events
    end

    def put_text(screen, y, x, text, style)
      return if text.nil? || text.empty?

      if @color_scheme && @color_scheme[style]
        screen.put_with_style(y, x, text, @color_scheme[style])
      else
        screen.put(y, x, text)
      end
    end
  end
end
