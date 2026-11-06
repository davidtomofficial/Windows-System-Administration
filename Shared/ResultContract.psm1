#Requires -Version 5.1
# In-memory result construction only. No execution, collection, files or network.
Set-StrictMode -Version Latest

function Stop-DTOResult([string]$Code) { throw ('DTO.InvalidTaskResult.' + $Code) }

function Assert-DTOResultRecord($Value, [string[]]$Keys) {
    if ($Value -is [hashtable] -or $Value -is [System.Collections.Specialized.OrderedDictionary]) {
        $actual = @($Value.Keys)
    } elseif ($Value -is [pscustomobject]) {
        $properties = @($Value.PSObject.Properties)
        if (@($properties | Where-Object { $_.MemberType -ne 'NoteProperty' }).Count -ne 0) {
            Stop-DTOResult 'RecordProperties'
        }
        $actual = @($properties | ForEach-Object { $_.Name })
    } else { Stop-DTOResult 'RecordType' }
    if ($actual.Count -ne $Keys.Count) { Stop-DTOResult 'RecordFields' }
    foreach ($key in $actual) {
        if ($key -isnot [string] -or $Keys -cnotcontains $key) { Stop-DTOResult 'RecordFields' }
    }
}

function Get-DTOResultField($Value, [string]$Name) {
    if ($Value -is [System.Collections.IDictionary]) { return ,$Value[$Name] }
    return ,$Value.PSObject.Properties[$Name].Value
}

function Assert-DTOResultInteger($Value, [long]$Minimum, [long]$Maximum) {
    if ($null -eq $Value -or $Value.GetType().FullName -notin @(
        'System.Byte','System.SByte','System.Int16','System.UInt16',
        'System.Int32','System.UInt32','System.Int64','System.UInt64'
    )) { Stop-DTOResult 'IntegerType' }
    if ([decimal]$Value -lt $Minimum -or [decimal]$Value -gt $Maximum) { Stop-DTOResult 'IntegerRange' }
}

function Assert-DTOResultText($Value, [int]$Maximum) {
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) { Stop-DTOResult 'Text' }
    $scalarCount = 0
    for ($i = 0; $i -lt $Value.Length; $i++) {
        $c = [int][char]$Value[$i]
        if ($c -lt 32 -or $c -eq 127) { Stop-DTOResult 'Text' }
        if ($c -ge 0xD800 -and $c -le 0xDBFF) {
            if ($i + 1 -ge $Value.Length) { Stop-DTOResult 'Text' }
            $next = [int][char]$Value[$i + 1]
            if ($next -lt 0xDC00 -or $next -gt 0xDFFF) { Stop-DTOResult 'Text' }
            $i++
        } elseif ($c -ge 0xDC00 -and $c -le 0xDFFF) { Stop-DTOResult 'Text' }
        $scalarCount++
    }
    if ($scalarCount -gt $Maximum) { Stop-DTOResult 'TextLength' }
}

function Assert-DTOResultToken($Value, [int]$Maximum) {
    if ($Value -isnot [string] -or $Value.Length -gt $Maximum -or
        $Value -cnotmatch '\A[A-Za-z][A-Za-z0-9._-]*\z') { Stop-DTOResult 'Token' }
}

function Assert-DTOResultEnum($Value, [string[]]$Allowed) {
    if ($Value -isnot [string] -or $Allowed -cnotcontains $Value) { Stop-DTOResult 'Enum' }
}

function Get-DTOResultTime($Value) {
    if ($null -eq $Value) { return $null }
    if ($Value -isnot [string] -or $Value -cnotmatch
        '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?(?:Z|\+00:00)\z') {
        Stop-DTOResult 'Timestamp'
    }
    if ([int]$Value.Substring(11, 2) -gt 23 -or [int]$Value.Substring(14, 2) -gt 59 -or
        [int]$Value.Substring(17, 2) -gt 59) { Stop-DTOResult 'Timestamp' }
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$parsed)) { Stop-DTOResult 'Timestamp' }
    return $parsed.UtcTicks
}

function Assert-DTOResultArray($Value) {
    if ($Value -isnot [Array] -or $Value.Rank -ne 1 -or $Value.Count -gt 128) { Stop-DTOResult 'Array' }
}

function Assert-DTOTaskResult {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowNull()]$InputObject)

    Assert-DTOResultRecord $InputObject @('schemaVersion','operationId','runId','operationKind',
        'source','startedAtUtc','completedAtUtc','changesAttempted','effects','restartRequired',
        'observation','action','verification','evidence')
    Assert-DTOResultInteger (Get-DTOResultField $InputObject 'schemaVersion') 1 1
    Assert-DTOResultToken (Get-DTOResultField $InputObject 'operationId') 128
    $runId = Get-DTOResultField $InputObject 'runId'
    if ($runId -isnot [string] -or $runId -cnotmatch
        '\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z') { Stop-DTOResult 'RunId' }
    $kind = Get-DTOResultField $InputObject 'operationKind'
    Assert-DTOResultEnum $kind @('Observation','Plan','Change')
    $source = Get-DTOResultField $InputObject 'source'
    Assert-DTOResultRecord $source @('component','version','revision')
    Assert-DTOResultText (Get-DTOResultField $source 'component') 128
    Assert-DTOResultText (Get-DTOResultField $source 'version') 64
    $revision = Get-DTOResultField $source 'revision'
    if ($revision -isnot [string] -or $revision -cnotmatch '\A[0-9a-f]{40}\z') { Stop-DTOResult 'Revision' }
    $started = Get-DTOResultTime (Get-DTOResultField $InputObject 'startedAtUtc')
    $completed = Get-DTOResultTime (Get-DTOResultField $InputObject 'completedAtUtc')
    if ($null -ne $started -and $null -ne $completed -and $completed -lt $started) { Stop-DTOResult 'TimeOrder' }
    $attempted = Get-DTOResultField $InputObject 'changesAttempted'
    if ($attempted -isnot [bool]) { Stop-DTOResult 'ChangesBoolean' }
    $effects = Get-DTOResultField $InputObject 'effects'
    Assert-DTOResultEnum $effects @('None','Observed','Unknown')
    $restart = Get-DTOResultField $InputObject 'restartRequired'
    if ($null -ne $restart -and $restart -isnot [bool]) { Stop-DTOResult 'RestartBoolean' }

    $evidence = Get-DTOResultField $InputObject 'evidence'
    Assert-DTOResultArray $evidence
    $ids = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $coverageById = New-Object 'Collections.Generic.Dictionary[string,string]' ([StringComparer]::Ordinal)
    foreach ($item in $evidence) {
        Assert-DTOResultRecord $item @('id','type','schemaVersion','collectedAtUtc','coverage','sha256')
        $id = Get-DTOResultField $item 'id'
        Assert-DTOResultToken $id 64
        if (-not $ids.Add($id)) { Stop-DTOResult 'DuplicateEvidence' }
        Assert-DTOResultText (Get-DTOResultField $item 'type') 128
        Assert-DTOResultInteger (Get-DTOResultField $item 'schemaVersion') 1 2147483647
        $null = Get-DTOResultTime (Get-DTOResultField $item 'collectedAtUtc')
        Assert-DTOResultEnum (Get-DTOResultField $item 'coverage') @('Complete','Partial','Unknown')
        $coverageById.Add($id, (Get-DTOResultField $item 'coverage'))
        $hash = Get-DTOResultField $item 'sha256'
        if ($null -ne $hash -and ($hash -isnot [string] -or $hash -cnotmatch '\A[0-9a-f]{64}\z')) {
            Stop-DTOResult 'EvidenceHash'
        }
    }

    $states = @('Succeeded','Failed','Partial','Skipped','Unknown','Cancelled','RestartRequired')
    $phaseStates = @{}
    foreach ($name in @('observation','action','verification')) {
        $phase = Get-DTOResultField $InputObject $name
        Assert-DTOResultRecord $phase @('status','reasonCode','evidenceIds')
        $status = Get-DTOResultField $phase 'status'
        Assert-DTOResultEnum $status $states
        Assert-DTOResultToken (Get-DTOResultField $phase 'reasonCode') 64
        $references = Get-DTOResultField $phase 'evidenceIds'
        Assert-DTOResultArray $references
        $seen = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
        foreach ($reference in $references) {
            Assert-DTOResultToken $reference 64
            if (-not $seen.Add($reference) -or -not $ids.Contains($reference)) { Stop-DTOResult 'EvidenceReference' }
        }
        if ($name -cne 'action' -and $status -ceq 'RestartRequired') { Stop-DTOResult 'RestartPhase' }
        if ($name -cne 'action' -and $status -ceq 'Succeeded' -and $references.Count -eq 0) {
            Stop-DTOResult 'SuccessEvidence'
        }
        if ($name -cne 'action' -and $status -ceq 'Succeeded') {
            foreach ($reference in $references) {
                if ($coverageById[$reference] -cne 'Complete') { Stop-DTOResult 'SuccessCoverage' }
            }
        }
        $phaseStates[$name] = $status
    }
    if ($kind -cne 'Change' -and ($phaseStates.action -cne 'Skipped' -or $attempted -or
        $effects -cne 'None' -or $restart -eq $true)) { Stop-DTOResult 'ReadOnlyEffects' }
    if (-not $attempted -and ($effects -cne 'None' -or $restart -eq $true -or
        $phaseStates.action -cin @('Succeeded','Partial','RestartRequired'))) { Stop-DTOResult 'AttemptEffects' }
    if ($attempted -and $phaseStates.action -ceq 'Skipped') { Stop-DTOResult 'SkippedAttempt' }
    if ($phaseStates.action -ceq 'RestartRequired' -and ($kind -cne 'Change' -or
        -not $attempted -or $restart -ne $true -or $phaseStates.verification -cnotin @('Skipped','Unknown'))) {
        Stop-DTOResult 'RestartBoundary'
    }
}

function New-DTOTaskResult {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowNull()]$InputObject)
    Assert-DTOTaskResult -InputObject $InputObject
    # Preserve source timestamps, nulls, evidence and phase states exactly as supplied.
    return $InputObject
}

function ConvertTo-DTOTaskResultJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowNull()]$InputObject)
    Assert-DTOTaskResult -InputObject $InputObject
    $json = ConvertTo-Json -InputObject $InputObject -Depth 8 -Compress
    if ([Text.Encoding]::UTF8.GetByteCount($json) -gt 1048576) { Stop-DTOResult 'ByteLimit' }
    return $json
}

Export-ModuleMember -Function Assert-DTOTaskResult,New-DTOTaskResult,ConvertTo-DTOTaskResultJson
