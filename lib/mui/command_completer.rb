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
      return COMMANDS.sort if prefix.empty?

      COMMANDS.select { |cmd| cmd.start_with?(prefix) }.sort
    end
  end
end
