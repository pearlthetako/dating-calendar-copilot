param(
    [Parameter(Mandatory = $true)]
    [string]$BusyFile,

    [Parameter(Mandatory = $true)]
    [datetime]$RangeStart,

    [Parameter(Mandatory = $true)]
    [datetime]$RangeEnd,

    [int]$SlotMinutes = 90,
    [int]$MaxSlots = 3,
    [string[]]$PreferredDays = @(),
    [int]$EarliestHour = 18,
    [int]$LatestHour = 22
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BusyFile)) {
    throw "Busy file not found: $BusyFile"
}

if ($RangeEnd -lt $RangeStart) {
    throw "RangeEnd must be on or after RangeStart."
}

if ($EarliestHour -ge $LatestHour) {
    throw "EarliestHour must be earlier than LatestHour."
}

$raw = Get-Content -LiteralPath $BusyFile -Raw | ConvertFrom-Json
$events = @()

foreach ($item in $raw) {
    if (-not $item.start -or -not $item.end) {
        continue
    }

    $start = [datetime]$item.start
    $end = [datetime]$item.end

    if ($end -le $start) {
        continue
    }

    $events += [pscustomobject]@{
        Start = $start
        End = $end
    }
}

$events = $events | Sort-Object Start, End

function Test-PreferredDay {
    param(
        [datetime]$Day,
        [string[]]$PreferredDays
    )

    if (-not $PreferredDays -or $PreferredDays.Count -eq 0) {
        return $true
    }

    return $PreferredDays -contains $Day.DayOfWeek.ToString()
}

function Find-WindowSlots {
    param(
        [datetime]$WindowStart,
        [datetime]$WindowEnd,
        [object[]]$Events,
        [timespan]$SlotLength
    )

    $cursor = $WindowStart
    $dayEvents = $Events | Where-Object { $_.End -gt $WindowStart -and $_.Start -lt $WindowEnd } | Sort-Object Start, End

    foreach ($event in $dayEvents) {
        if ($event.Start -gt $cursor) {
            $gapEnd = if ($event.Start -lt $WindowEnd) { $event.Start } else { $WindowEnd }
            if (($gapEnd - $cursor) -ge $SlotLength) {
                [pscustomobject]@{ Start = $cursor; End = $cursor.Add($SlotLength) }
            }
        }

        if ($event.End -gt $cursor) {
            $cursor = $event.End
        }

        if ($cursor -ge $WindowEnd) {
            return
        }
    }

    if (($WindowEnd - $cursor) -ge $SlotLength) {
        [pscustomobject]@{ Start = $cursor; End = $cursor.Add($SlotLength) }
    }
}

$slotLength = New-TimeSpan -Minutes $SlotMinutes
$results = @()
$day = $RangeStart.Date
$lastDay = $RangeEnd.Date

while ($day -le $lastDay -and $results.Count -lt $MaxSlots) {
    if (Test-PreferredDay -Day $day -PreferredDays $PreferredDays) {
        $windowStart = $day.AddHours($EarliestHour)
        $windowEnd = $day.AddHours($LatestHour)

        if ($windowStart -lt $RangeStart) {
            $windowStart = $RangeStart
        }

        if ($windowEnd -gt $RangeEnd.AddDays(1)) {
            $windowEnd = $RangeEnd.AddDays(1)
        }

        if ($windowEnd -gt $windowStart) {
            $slots = Find-WindowSlots -WindowStart $windowStart -WindowEnd $windowEnd -Events $events -SlotLength $slotLength
            foreach ($slot in $slots) {
                $results += [pscustomobject]@{
                    start = $slot.Start.ToString("s")
                    end = $slot.End.ToString("s")
                    day = $slot.Start.DayOfWeek.ToString()
                }

                if ($results.Count -ge $MaxSlots) {
                    break
                }
            }
        }
    }

    $day = $day.AddDays(1)
}

$results | ConvertTo-Json
