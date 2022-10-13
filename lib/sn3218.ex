defmodule Sn3218 do
  @moduledoc """
  Documentation for `Sn3218`.
  """

  use GenServer
  alias Sn3218.Channel
  alias Circuits.I2C
  alias __MODULE__

  defstruct [
    address: 0x54,
    channels: [],
    enabled?: false,
    bus_name: "i2c-1",
    bus_ref: nil
  ]

  @type t :: %__MODULE__{
    address: integer(),
    channels: list(%Channel{}),
    bus_name: String.t(),
    enabled?: boolean(),
    bus_ref: reference()
  }

  # Client API
  def start_link(device = %Sn3218{}) do
    GenServer.start_link(__MODULE__, device)
  end

  def enable_device(pid) do
    GenServer.cast(pid, :enable_device)
  end

  def disable_device(pid) do
    GenServer.cast(pid, :disable_device)
  end

  def reset_device(pid) do
    GenServer.cast(pid, :reset_device)
  end

  def device_state(pid) do
    GenServer.call(pid, :device_state)
  end

  def update(pid, channel) do
    GenServer.cast(pid, {:update_channel, channel})
  end

  # GenServer callbacks
  @impl true
  def init(%Sn3218{bus_name: bus_name} = device) do
    {:ok, bus_ref} = I2C.open(bus_name)
    {:ok, %{device | bus_ref: bus_ref, channels: 1..18 |> Enum.map(&Channel.init_channel/1)}}
  end

  @impl true
  def handle_cast(:enable_device, %Sn3218{address: address, bus_ref: bus_ref} = device) do
    case I2C.write(bus_ref, address, <<0x00, 0x01>>) do
      :ok ->
        {:noreply, %{device | enabled?: true}}
      _ ->
        {:stop, :enable_device_failed}
    end
  end

  def handle_cast(:disable_device, %Sn3218{address: address, bus_ref: bus_ref} = device) do
    case I2C.write(bus_ref, address, <<0x00, 0x00>>) do
      :ok ->
        {:noreply, %{device | enabled?: false}}
      _ ->
        {:stop, :disable_device_failed}
    end
  end

  def handle_cast(:reset_device, %Sn3218{address: address, bus_ref: bus_ref} = device) do
    case I2C.write(bus_ref, address, <<0x17, 0x01>>) do
      :ok ->
        {:noreply, %{device | enabled?: false, channels: 1..18 |> Enum.map(&Channel.init_channel/1)}}
      _ ->
        {:stop, :reset_device_failed}
    end
  end

  def handle_cast({:update_channel, channel}, %Sn3218{channels: channels} = device) do
    # need to update struct and write to registers
    device =
      %{device| channels: List.update_at(channels, channel.id - 1, fn _ -> channel end)}
      |> write_pwm_control_registers()
      |> write_pwm_values()
      |> write_pwm_update()
    {:noreply, device}
  end


  @impl true
  def handle_call(:device_state, _from, device) do
    {:reply, device, device}
  end

  defp write_pwm_update(%Sn3218{bus_ref: bus_ref, address: address} = device) do
    I2C.write(bus_ref, address, <<0x16, 0x01>>)
    device
  end

  defp write_pwm_values(%Sn3218{bus_ref: bus_ref, address: address, channels: channels} = device) do
    for channel <- channels do
      I2C.write(bus_ref, address, <<channel.id, channel.output>>)
    end
    device
  end

  defp write_pwm_control_registers(%Sn3218{channels: channels, bus_ref: bus_ref, address: address} = device) do
    control_registers = channels |> Enum.group_by(fn x -> div(x.id - 1, 6) end)

    for register <- 0..2 do
      register_value =
        control_registers[register]
        |> Enum.reduce([0, 0, 0, 0, 0, 0], fn x, acc ->
          bit_value =
            if (x.enabled?) do
              1
            else
              0
            end
          idx =
            case rem(x.id, 6) do
              0 -> 0
              idx -> 6 - idx
            end
          List.replace_at(acc, idx, bit_value)
        end)
        |> Enum.join()
        |> String.to_integer(2)
      register_address = 0x13 + register
      :ok = I2C.write(bus_ref, address, <<register_address, register_value>>)
    end
    device
  end
end
