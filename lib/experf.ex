require Logger

defmodule Experf do
  def main(args) do
    options = parse_args(args)

    Logger.info inspect(options)
  end

  def parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [n: :integer, url: :string]
    )
    Enum.into(options, %{})
  end
end
