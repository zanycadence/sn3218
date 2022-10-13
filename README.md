# Sn3218

An Elixir package for working with the SN3218 18 channel LED Driver. Each channel has an 8-bit PWM output to adjust LED brightness (or any other output that requires PWM control). Board-specific code for the [PiGlow](https://shop.pimoroni.com/products/piglow) Raspberry Pi Hat will be included as well.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sn3218` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sn3218, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/sn3218>.

