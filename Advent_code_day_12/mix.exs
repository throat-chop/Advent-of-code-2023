defmodule AdventOfCodeDay12.MixProject do
  use Mix.Project

  def project do
    [app: :AdventOfCodeDay12, version: "1.0.0", escript: escript()]
  end

  defp escript do
    [main_module: Spr2]
  end
end
