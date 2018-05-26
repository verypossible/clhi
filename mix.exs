defmodule Clhi.MixProject do
  use Mix.Project

  def project do
    [
      app: :clhi,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: [{:ex_doc, "~> 0.0", only: :dev}],
      package: package()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp package do
    [
      description: "A CLI helper for asking questions.",
      maintainers: ["Very"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/verypossible/clhi"}
    ]
  end
end
