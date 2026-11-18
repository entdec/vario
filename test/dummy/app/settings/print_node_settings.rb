# frozen_string_literal: true

class PrintNodeSettings < Vario::Topic
  settable Account
  icon 'fal fa-print'
  context environment: :string

  setting :api_key, :string
end
