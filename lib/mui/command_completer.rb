# frozen_string_literal: true

module Mui
  # Provides command name completion
  class CommandCompleter
    COMMANDS = %w[
      e w q wq q!
      sp split vs vsplit close only
      tabnew tabe tabedit tabclose tabc
      tabnext tabn tabprev tabp tabprevious
      tabfirst tabf tabrewind tabr tablast tabl
      tabmove tabm
    ].freeze

    def complete(prefix)
      all_commands = COMMANDS + plugin_command_names

      return all_commands.uniq.sort if prefix.empty?

      prefix_downcase = prefix.downcase
      all_commands.select { |cmd| cmd.downcase.start_with?(prefix_downcase) }.uniq.sort
    end

    private

    def plugin_command_names
      Mui.config.commands.keys.map(&:to_s)
    end
  end
end
