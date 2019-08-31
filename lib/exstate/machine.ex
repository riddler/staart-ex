defmodule Exstate.Machine do
  defstruct [
    # Definition of the machine
    :statechart,

    # Root state
    :root,

    :states,

    # Currently active states
    :configuration
  ]

  def new statechart do
    root = Exstate.State.new(statechart.root)

    %__MODULE__{
      #statechart: statechart,
      root: root,
      states: Exstate.State.gather_states(root),
      configuration: Exstate.Configuration.initial(root)
    }
  end

  # Literal representation of the configuration
  def configuration_literal(%__MODULE__{} = machine) do
    Exstate.Configuration.literal machine.configuration
  end

  # Transitions defined on current configuration
  def transitions(%__MODULE__{} = machine) do
    machine.configuration.active
    |> Enum.map(fn state -> state.transitions end)
    |> List.flatten
  end

  def send(%__MODULE__{} = machine, event) do
    matching_transitions = machine
      |> transitions
      |> Enum.filter(fn transition -> transition.event == event end)

    if length(matching_transitions) == 0 do
      machine
    else
      machine
      |> transition!(matching_transitions)
    end
  end

  def transition!(%__MODULE__{} = machine, transitions) do
    changes = transitions
      |> Enum.map(fn transition ->
          %{
            source: machine.states |> Enum.find(fn state -> state.id == transition.source end),
            target: machine.states |> Enum.find(fn state -> state.id == transition.target end)
          }
        end)


    new_states = changes
      |> Enum.reduce(machine.configuration.active, fn x, acc ->
        new_list = acc |> List.delete(x.source)
        new_list ++ [x.target]
      end)

    %__MODULE__{machine | configuration: Exstate.Configuration.new(new_states)}
  end
end
