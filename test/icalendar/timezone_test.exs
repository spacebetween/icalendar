defmodule ICalendar.TimezoneTest do
  use ExUnit.Case

  alias ICalendar.Timezone

  test "ICalendar.to_ics/1 of timezone" do
    ics = %Timezone{} |> ICalendar.to_ics()

    assert ics == """
           BEGIN:VTIMEZONE
           END:VTIMEZONE
           """
  end

  test "ICalendar.to_ics/1 with some attributes" do
    tomezone =
      %Timezone{
        tzid: "America/Toronto",
        tzoffsetfrom: -500,
        tzoffsetto: -400,
        tzname: "PST",
        standard: %Timezone.Standard{
          tzoffsetfrom: -500,
          tzoffsetto: -400,
          tzname: "PST"
        },
        daylight: %Timezone.Daylight{
          dtstart: ~U[2020-09-16 18:30:00Z],
          tzoffsetfrom: -400,
          tzoffsetto: -500,
          tzname: "PDT",
          rdate: [
            ~U[2020-09-17 18:30:00Z],
            ~U[2020-09-18 18:30:00Z]
          ]
        }
      }

    ics = ICalendar.to_ics(tomezone)

    assert ics == """
           BEGIN:VTIMEZONE
           TZID:America/Toronto
           TZNAME:PST
           TZOFFSETFROM:-0500
           TZOFFSETTO:-0400
           BEGIN:STANDARD
           TZNAME:PST
           TZOFFSETFROM:-0500
           TZOFFSETTO:-0400
           END:STANDARD
           BEGIN:DAYLIGHT
           DTSTART:20200916T183000Z
           RDATE:20200917T183000Z
           RDATE:20200918T183000Z
           TZNAME:PDT
           TZOFFSETFROM:-0400
           TZOFFSETTO:-0500
           END:DAYLIGHT
           END:VTIMEZONE
           """
  end
end
