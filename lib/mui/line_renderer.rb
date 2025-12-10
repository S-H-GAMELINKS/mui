# frozen_string_literal: true

module Mui
  class LineRenderer
    def initialize(color_scheme)
      @color_scheme = color_scheme
      @highlighters = []
      @resolved_styles = {} # Cache for resolved styles
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
      return [] if highlights.empty?

      events = []
      highlights.each do |h|
        start_col = [h.start_col, 0].max
        end_col = [h.end_col, line_length - 1].min
        next if start_col > end_col

        events << [start_col, 1, h] # 1 = start (sorted after end at same position)
        events << [end_col + 1, 0, h] # 0 = end
      end
      # Sort by position, then by type (end before start at same position)
      events.sort!
      # Convert back to hash format
      events.map! { |pos, type, h| { pos:, type: type == 1 ? :start : :end, highlight: h } }
      events
    end

    def put_text(screen, y, x, text, style)
      return if text.nil? || text.empty?

      if @color_scheme && @color_scheme[style]
        resolved_style = resolve_style(style)
        screen.put_with_style(y, x, text, resolved_style)
      else
        screen.put(y, x, text)
      end
    end

    def resolve_style(style)
      # Use cached resolved style if available
      return @resolved_styles[style] if @resolved_styles.key?(style)

      style_hash = @color_scheme[style]
      resolved = if style_hash[:bg]
                   style_hash
                 else
                   # Inherit background from :normal if not specified
                   normal_style = @color_scheme[:normal]
                   normal_style ? style_hash.merge(bg: normal_style[:bg]) : style_hash
                 end

      @resolved_styles[style] = resolved
      resolved
    end
  end
end
