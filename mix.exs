defmodule SumMag.MixProject do
  use Mix.Project

  def project do
    [
      app: :sum_mag,
      version: "0.0.8",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :ex_doc,      ">= 0.0.0", only: :dev}
    ]
  end
  defp description() do
    "SumMag: a meta-programming library for Hastega and Cockatorice."
  end

  defp package() do
    [
      name: "sum_mag",
      maintainers: ["Susumu Yamazaki", "Masakazu Mori", "Yoshihiro Ueno", "Hideki Takase"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/zeam-vm/sum_mag"}
    ]
  end

end
