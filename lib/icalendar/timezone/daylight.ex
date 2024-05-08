defmodule ICalendar.Timezone.Daylight do
  @moduledoc """
  Timezone has daylight saving times
  """

  defstruct dtstart: nil,
            tzoffsetfrom: nil,
            tzoffsetto: nil,
            tzname: nil,
            rdate: nil

  @type t :: %__MODULE__{
          dtstart: DateTime.t(),
          tzoffsetfrom: integer(),
          tzoffsetto: integer(),
          tzname: String.t(),
          rdate: [DateTime.t()]
        }

  defimpl ICalendar.Serialize, for: ICalendar.Timezone.Daylight do
    alias ICalendar.Util.KV

    def to_ics(%ICalendar.Timezone.Daylight{} = daylight, _options \\ []) do
      contents = to_kvs(daylight)

      """
      BEGIN:DAYLIGHT
      #{contents}END:DAYLIGHT
      """
    end

    defp to_kvs(daylight) do
      daylight
      |> Map.from_struct()
      |> Enum.map(&to_kv/1)
      |> List.flatten()
      |> Enum.sort()
      |> Enum.join()
    end

    defp to_kv({key, value}) do
      name = key |> to_string |> String.upcase()
      KV.build(name, value)
    end
  end
end
