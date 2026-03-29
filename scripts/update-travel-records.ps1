param(
  [string]$InputCsv = "travel-data/travel-records.csv",
  [string]$OutputJson = "data/travel_records.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputCsv)) {
  throw "Input CSV not found: $InputCsv"
}

function Normalize-Text([string]$Value) {
  $t = [string]$Value
  $t = $t -replace "[\uFEFF\u200B\u00A0]", " "
  $t = $t.Trim()
  $t = $t.TrimStart("`"","'","-","_",".",",",";","?")
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t
}

function Normalize-Key([string]$Value) {
  $t = (Normalize-Text $Value).ToLowerInvariant()
  $t = [regex]::Replace($t, '[^a-z0-9 ]', '')
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t.Trim()
}

function Normalize-Date([string]$Value) {
  $raw = Normalize-Text $Value
  if (-not $raw) { return "" }

  if ($raw -match '^(\d{4})-(\d{2})-\*\*$') {
    return "$($matches[1])-$($matches[2])-**"
  }

  if ($raw -match '^\d{4}-\d{2}-\d{2}$') { return $raw }
  if ($raw -match '^(\d{4})/(\d{2})/(\d{2})$') { return "$($matches[1])-$($matches[2])-$($matches[3])" }
  if ($raw -match '^(\d{4})\.(\d{2})\.(\d{2})$') { return "$($matches[1])-$($matches[2])-$($matches[3])" }

  try {
    $dt = Get-Date -Date $raw
    if ($dt) { return $dt.ToString('yyyy-MM-dd') }
  } catch {}

  return ""
}

$countryAlias = @{
  'uk' = 'United Kingdom'
  'u.k.' = 'United Kingdom'
  'united kingdom' = 'United Kingdom'
  'usa' = 'USA'
  'u.s.a.' = 'USA'
  'us' = 'USA'
  'u.s.' = 'USA'
  'russian federation' = 'Russia'
  'russia' = 'Russia'
  'northern mariana islands' = 'Northern Mariana Islands'
  'orthern mariana islands' = 'Northern Mariana Islands'
}

$cityAlias = @{
  'cophenhagen' = 'Copenhagen'
  'newyork' = 'New York'
  'newyork ny' = 'New York NY'
  'new york city' = 'New York NY'
  'st petersburg' = 'St Petersburg'
}

$rows = Import-Csv -LiteralPath $InputCsv | ForEach-Object {
  $country = Normalize-Text ([string]$_.country)
  $city = Normalize-Text ([string]$_.city)
  $purpose = Normalize-Text ([string]$_.purpose)

  $countryKey = Normalize-Key $country
  if (-not $countryKey -and $country) { $countryKey = $country.ToLowerInvariant() }
  if ($countryAlias.ContainsKey($countryKey)) { $country = $countryAlias[$countryKey] }
  if ($country -match '(?i)russian\s*federation') { $country = 'Russia' }

  $cityKey = Normalize-Key $city
  if (-not $cityKey -and $city) { $cityKey = $city.ToLowerInvariant() }
  if ($cityAlias.ContainsKey($cityKey)) { $city = $cityAlias[$cityKey] }

  $arrival = Normalize-Date ([string]$_.arrival)
  $departure = Normalize-Date ([string]$_.departure)
  if (-not $departure -and $arrival) { $departure = $arrival }

  [ordered]@{
    country = $country
    city = $city
    arrival = $arrival
    departure = $departure
    purpose = $purpose
  }
}

$payload = [ordered]@{
  records = @($rows)
}

$json = $payload | ConvertTo-Json -Depth 5
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path -Parent $OutputJson) | ForEach-Object { Join-Path $_ (Split-Path -Leaf $OutputJson) }), $json, $utf8NoBom)

Write-Output "Updated $OutputJson from $InputCsv"
