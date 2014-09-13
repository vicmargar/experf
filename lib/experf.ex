require Logger

defmodule Experf do
  def main(args) do
    options = parse_args(args)

    Logger.info inspect(options)
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [n: :integer, url: :string]
    )
    options
  end
end
