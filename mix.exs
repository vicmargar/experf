defmodule Experf.Mixfile do
  use Mix.Project

  def project do
    [ app: :experf,
      version: "0.0.1",
      elixir: "~> 0.11.2",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
  [ applications: [:ssl, :lhttpc],
    registered: [:results],
    mod: { Experf, [] } ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat.git" }
  defp deps do
    [{ :lhttpc, github: "esl/lhttpc"},
     {:descriptive_statistics, github: "pusewicz/descriptive_statistics"}
    ]
  end
end
