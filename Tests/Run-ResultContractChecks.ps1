#Requires -Version 5.1
# Trusted synthetic fixtures only. This is not a saved-report import API.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'Shared/ResultContract.psm1') -Force
$checks = 0

function Confirm([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw ('Result contract check failed: ' + $Name) }
    $script:checks++
}

# PowerShell ships Json.NET for ConvertFrom-Json. Disable its date coercion
# explicitly when loading known repository fixtures, including on older PS7.
$null = ConvertFrom-Json -InputObject '{}'
$settings = New-Object Newtonsoft.Json.JsonSerializerSettings
$settings.DateParseHandling = [Newtonsoft.Json.DateParseHandling]::None
function ConvertFrom-TrustedFixtureToken($Token) {
    switch ($Token.Type.ToString()) {
        'Object' {
            $record = [ordered]@{}
            foreach ($property in $Token.Properties()) {
                $record[$property.Name] = ConvertFrom-TrustedFixtureToken $property.Value
            }
            return ,$record
        }
        'Array' {
            $rows = New-Object 'Collections.Generic.List[object]'
            foreach ($item in $Token.Children()) { $rows.Add((ConvertFrom-TrustedFixtureToken $item)) }
            return ,$rows.ToArray()
        }
        'Null' { return $null }
        default { return ,$Token.Value }
    }
}
$fixturePath = Join-Path $root 'Contracts/fixtures/task-result-cases.json'
$raw = [IO.File]::ReadAllText($fixturePath, [Text.Encoding]::UTF8)
$token = [Newtonsoft.Json.JsonConvert]::DeserializeObject($raw, $settings)
$fixtures = ConvertFrom-TrustedFixtureToken $token
Confirm ($fixtures.fixtureSchemaVersion -eq 1) 'fixture version'
$emitted = New-Object 'Collections.Generic.List[string]'
foreach ($case in $fixtures.cases) {
    $accepted = $true
    try { $created = New-DTOTaskResult -InputObject $case.result }
    catch { $accepted = $false }
    Confirm ($accepted -eq $case.valid) ('shared fixture ' + $case.id)
    if ($case.valid) {
        Confirm ([object]::ReferenceEquals($created, $case.result)) ('no mutation ' + $case.id)
        $json = ConvertTo-DTOTaskResultJson -InputObject $created
        Confirm ($json -is [string] -and [Text.Encoding]::UTF8.GetByteCount($json) -le 1048576) ('serialization ' + $case.id)
        $emitted.Add($json)
    }
}

# The constructor must not read script properties or permit a mutated value at
# serialization time. Normal dictionaries and PSCustomObject note properties work.
$scripted = [pscustomobject]@{ schemaVersion = 1 }
$scripted | Add-Member -MemberType ScriptProperty -Name source -Value { throw 'Getter must not execute' }
$refused = $false
try { Assert-DTOTaskResult $scripted } catch { $refused = $_.Exception.Message -eq 'DTO.InvalidTaskResult.RecordProperties' }
Confirm $refused 'script property refused without evaluation'
$valid = @($fixtures.cases | Where-Object { $_.valid })[0].result
$noteObject = [pscustomobject]$valid
$null = New-DTOTaskResult $noteObject
Confirm $true 'PSCustomObject supported'
$oldVersion = $valid.schemaVersion
try {
    $valid.schemaVersion = $true
    $refused = $false
    try { $null = ConvertTo-DTOTaskResultJson $valid } catch { $refused = $true }
    Confirm $refused 'serialization revalidates mutated input'
} finally { $valid.schemaVersion = $oldVersion }

# Validate the actual PowerShell-produced bytes through the future Python
# consumer and compare every value with its original shared fixture.
$temp = Join-Path ([IO.Path]::GetTempPath()) ('dto-result-' + [guid]::NewGuid().ToString('N') + '.jsonl')
try {
    [IO.File]::WriteAllLines($temp, $emitted.ToArray(), (New-Object Text.UTF8Encoding($false)))
    & python (Join-Path $PSScriptRoot 'check_result_parity.py') $temp
    if ($LASTEXITCODE -ne 0) { throw 'PowerShell/Python result parity failed' }
    Confirm $true 'actual serialized bytes accepted and unchanged in Python'
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
}
Write-Output ('RESULT_CONTRACT_CHECKS_PASSED=' + $checks)
Write-Output ('RESULT_CONTRACT_SHARED_CASES=' + $fixtures.cases.Count)
Write-Output ('RESULT_CONTRACT_VALID_SERIALIZED=' + $emitted.Count)
Write-Output ('POWERSHELL_VERSION=' + $PSVersionTable.PSVersion.ToString())
