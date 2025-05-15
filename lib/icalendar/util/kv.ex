defmodule ICalendar.Util.KV do
  @moduledoc """
  Build ICalendar key-value strings.
  """

  alias ICalendar.Value

  @doc ~S"""
  Convert a key and value to an iCal line:

      iex> ICalendar.Util.KV.build("foo", "bar")
      "foo:bar\n"

  Don't add empty values:

      iex> ICalendar.Util.KV.build("foo", nil)
      ""

  DateTime values will add timezones:

      iex> date =
      ...>   {{2015, 12, 24}, {8, 30, 0}}
      ...>   |> Timex.to_datetime("America/Chicago")
      ...> ICalendar.Util.KV.build("foo", date)
      "foo;TZID=America/Chicago:20151224T083000\n"

  Attendees get their own line, each:

        iex> attendees = [
        ...>   %{"PARTSTAT" => "ACCEPTED", "CN" => "eric@clockk.com", original_value: "mailto:eric@clockk.com"},
        ...>   %{"PARTSTAT" => "ACCEPTED", "CN" => "paul@clockk.com", original_value: "mailto:paul@clockk.com"},
        ...>   %{"PARTSTAT" => "ACCEPTED", "CN" => "James SM", original_value: "mailto:james@clockk.com"},
        ...> ]
        iex> ICalendar.Util.KV.build("ATTENDEES", attendees)
        "ATTENDEE;CN=eric@clockk.com;PARTSTAT=ACCEPTED:mailto:eric@clockk.com\n" <>
          "ATTENDEE;CN=paul@clockk.com;PARTSTAT=ACCEPTED:mailto:paul@clockk.com\n" <>
          "ATTENDEE;CN=James SM;PARTSTAT=ACCEPTED:mailto:james@clockk.com\n"

  """
  def build(_, nil) do
    ""
  end

  def build("LOCATION" = key, value) do
    build_sanitized(key, Value.to_ics(value))
  end

  def build("DESCRIPTION" = key, value) do
    build_sanitized(key, Value.to_ics(value))
  end

  def build("CATEGORIES", value) do
    "CATEGORIES:#{Enum.join(Value.to_ics(value), ",")}\n"
  end

  def build("STATUS" = key, value) do
    build_sanitized(key, Value.to_ics(value |> to_string |> String.upcase()))
  end

  def build("CLASS" = key, value) do
    build_sanitized(key, Value.to_ics(value |> to_string |> String.upcase()))
  end

  def build("GEO" = key, {lat, lon}) do
    "#{key}:#{lat};#{lon}\n"
  end

  def build("RRULE", rrules) when is_map(rrules) do
    # FREQ rule part MUST be the first rule part specified in a RECUR value.
    freq = rrules.freq

    rrule_tail_part =
      rrules
      |> Map.delete(:freq)
      |> Enum.map(fn {key, value} ->
        value =
          case {key, value} do
            {:until, value} ->
              Value.to_ics(value)

            {_key, values} when is_list(values) ->
              Enum.join(values, ",")

            {_key, value} ->
              # All other values can simply be interpolated
              value
          end

        key = key |> Atom.to_string() |> String.upcase()
        ";#{key}=#{value}"
      end)
      |> Enum.join("")

    "RRULE:FREQ=#{freq}#{rrule_tail_part}\n"
  end

  def build("ATTENDEES", attendees) do
    Enum.map(attendees, fn attendee ->
      params =
        for {key, val} <- attendee, key != :original_value, into: "" do
          ";#{key}=#{val}"
        end

      "ATTENDEE#{params}:#{attendee.original_value}\n"
    end)
    |> Enum.join("")
  end

  def build("ATTACHMENTS", attachments) do
    Enum.map(attachments, fn attachment ->
      params =
        for {key, val} <- attachment, key != :original_value, into: "" do
          ";#{key}=#{val}"
        end

      "ATTACH#{params}:#{attachment.original_value}\n"
    end)
    |> Enum.join("")
  end

  def build("ORGANIZER", organizer) do
    params =
      for {key, val} <- organizer, key != :original_value, into: "" do
        ";#{key}=#{val}"
      end

    "ORGANIZER#{params}:#{organizer.original_value}\n"
  end

  def build("ACTION", value) do
    "ACTION:#{String.upcase(Value.to_ics(value))}\n"
  end

  def build("TRIGGER", value) when is_binary(value) and binary_part(value, 0, 1) == "-" do
    # Handle duration-based triggers like "-PT15M"
    "TRIGGER:#{value}\n"
  end

  def build("TRIGGER", value) when is_binary(value) and binary_part(value, 0, 1) == "P" do
    # Handle duration-based triggers like "PT15M"
    "TRIGGER:#{value}\n"
  end

  def build("TRIGGER", date = %DateTime{}) do
    # Handle date-time based triggers
    "TRIGGER;VALUE=DATE-TIME:#{Value.to_ics(date)}\n"
  end

  def build("REPEAT", value) when is_integer(value) do
    "REPEAT:#{value}\n"
  end

  def build("DURATION", value) when is_binary(value) and binary_part(value, 0, 1) == "P" do
    "DURATION:#{value}\n"
  end

  def build(key, value) when key in ["TZOFFSETFROM", "TZOFFSETTO"] and is_integer(value) do
    value =
      value
      |> then(&if(&1 < 0, do: {"-", "#{&1 * -1}"}, else: {"+", "#{&1}"}))
      |> then(fn {h, m} -> "#{h}#{String.pad_leading(m, 4, "0")}" end)

    "#{key}:#{value}\n"
  end

  def build(key, date = %DateTime{time_zone: "Etc/UTC"}) do
    "#{key}:#{Value.to_ics(date)}Z\n"
  end

  def build(key, date = %DateTime{}) do
    "#{key};TZID=#{date.time_zone}:#{Value.to_ics(date)}\n"
  end

  def build(key, values) when is_list(values) do
    Enum.map(values, &build(key, &1))
  end

  def build(key, value) do
    "#{key}:#{Value.to_ics(value)}\n"
  end

  defp build_sanitized(key, value) do
    "#{key}:#{sanitize(value)}\n"
  end

  defp sanitize(string) when is_bitstring(string) do
    string
    |> String.replace(~r{([\,;])}, "\\\\\\g{1}")
  end
end
