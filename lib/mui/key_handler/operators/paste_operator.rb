# frozen_string_literal: true

module Mui
  module KeyHandler
    module Operators
      # Handles paste operator (p/P) in Normal mode
      class PasteOperator < BaseOperator
        # Paste after cursor (p)
        def paste_after(pending_register: nil)
          return :done if @register.empty?(name: pending_register)

          if @register.linewise?(name: pending_register)
            paste_line_after(name: pending_register)
          else
            paste_char_after(name: pending_register)
          end
          :done
        end

        # Paste before cursor (P)
        def paste_before(pending_register: nil)
          return :done if @register.empty?(name: pending_register)

          if @register.linewise?(name: pending_register)
            paste_line_before(name: pending_register)
          else
            paste_char_before(name: pending_register)
          end
          :done
        end

        # Not used for paste, but required by base class interface
        def handle_pending(_char, pending_register: nil) # rubocop:disable Lint/UnusedMethodArgument
          :cancel
        end

        private

        def paste_line_after(name: nil)
          text = @register.get(name:)
          lines = text.split("\n", -1)
          lines.reverse_each do |line|
            @buffer.insert_line(cursor_row + 1, line)
          end
          self.cursor_row = cursor_row + 1
          self.cursor_col = 0
        end

        def paste_line_before(name: nil)
          text = @register.get(name:)
          lines = text.split("\n", -1)
          lines.reverse_each do |line|
            @buffer.insert_line(cursor_row, line)
          end
          self.cursor_col = 0
        end

        def paste_char_after(name: nil)
          text = @register.get(name:)
          line = @buffer.line(cursor_row)
          insert_col = line.empty? ? 0 : cursor_col + 1

          if text.include?("\n")
            paste_multiline_char(text, line, insert_col)
          else
            @buffer.lines[cursor_row] = line[0...insert_col].to_s + text + line[insert_col..].to_s
            self.cursor_col = insert_col + text.length - 1
            @window.clamp_cursor_to_line(@buffer)
          end
        end

        def paste_char_before(name: nil)
          text = @register.get(name:)
          line = @buffer.line(cursor_row)

          if text.include?("\n")
            paste_multiline_char(text, line, cursor_col)
          else
            @buffer.lines[cursor_row] = line[0...cursor_col].to_s + text + line[cursor_col..].to_s
            self.cursor_col = cursor_col + text.length - 1
            @window.clamp_cursor_to_line(@buffer)
          end
        end

        def paste_multiline_char(text, line, insert_col)
          lines = text.split("\n", -1)
          before = line[0...insert_col].to_s
          after = line[insert_col..].to_s

          # First line: before + first part of pasted text
          @buffer.lines[cursor_row] = before + lines.first

          # Middle lines: insert as new lines
          lines[1...-1].each_with_index do |pasted_line, idx|
            @buffer.insert_line(cursor_row + 1 + idx, pasted_line)
          end

          # Last line: last part of pasted text + after
          if lines.length > 1
            last_line_row = cursor_row + lines.length - 1
            @buffer.insert_line(last_line_row, lines.last + after)
          end

          # Position cursor at the end of pasted text (before 'after' part)
          self.cursor_row = cursor_row + lines.length - 1
          self.cursor_col = lines.last.length - 1
          self.cursor_col = 0 if cursor_col.negative?
          @window.clamp_cursor_to_line(@buffer)
        end
      end
    end
  end
end
