#Requires -Version 5.1
# In-memory explanation contracts. No collection, transport, file writes or actions.

function Get-DTOExplanationProperty {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [hashtable] -or $Object -is [Collections.Specialized.OrderedDictionary]) {
        return ,$Object[$Name]
    }
    if ($Object -isnot [pscustomobject]) { throw 'DTO.InvalidExplanationInput.Record' }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    if ($property.MemberType -ne 'NoteProperty') { throw 'DTO.InvalidExplanationInput.Record' }
    return ,$property.Value
}

function ConvertTo-DTOExplanationNumber {
    param($Value)
    if ($null -eq $Value -or $Value.GetType().FullName -notin @(
        'System.Byte','System.SByte','System.Int16','System.UInt16','System.Int32','System.UInt32',
        'System.Int64','System.UInt64','System.Single','System.Double','System.Decimal'
    )) { return $null }
    $number = [double]$Value
    if ([double]::IsNaN($number) -or [double]::IsInfinity($number) -or $number -lt 0) { return $null }
    return $number
}

function Assert-DTOExplanationRecord {
    param($Value, [string[]]$Names)
    if ($Value -is [hashtable] -or $Value -is [Collections.Specialized.OrderedDictionary]) {
        $actual = @($Value.Keys)
    } elseif ($Value -is [pscustomobject]) {
        $properties = @($Value.PSObject.Properties)
        if (@($properties | Where-Object { $_.MemberType -ne 'NoteProperty' }).Count -ne 0) {
            throw 'DTO.InvalidExplanationResponse.Record'
        }
        $actual = @($properties | ForEach-Object { $_.Name })
    } else { throw 'DTO.InvalidExplanationResponse.Record' }
    if ($actual.Count -ne $Names.Count) { throw 'DTO.InvalidExplanationResponse.Fields' }
    foreach ($name in $actual) {
        if ($name -isnot [string] -or $Names -cnotcontains $name) {
            throw 'DTO.InvalidExplanationResponse.Fields'
        }
    }
}

function Assert-DTOExplanationText {
    param($Value, [int]$Maximum)
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt $Maximum) {
        throw 'DTO.InvalidExplanationResponse.Text'
    }
    # Plain paragraphs only: reject markup, hidden/control characters, links and code fences.
    if ($Value -match '[\p{Cc}\p{Cf}\p{Cs}<>`*_\[\]]' -or
        $Value -match '(?m)^\s*#{1,6}\s' -or
        $Value -match '(?i)\b(?:https?|ftp|file|mailto|data|javascript):|\b[a-z][a-z0-9+.-]*://|//\S|\bwww\.' -or
        $Value -match '(?i)\b(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}\b') {
        throw 'DTO.InvalidExplanationResponse.Text'
    }
}

function New-DTODeviceCareExplanationRequest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowNull()]$Assessment)

    $schema = Get-DTOExplanationProperty $Assessment 'SchemaVersion'
    $authorized = Get-DTOExplanationProperty $Assessment 'MaintenanceAuthorized'
    $product = Get-DTOExplanationProperty $Assessment 'Product'
    $assessmentType = Get-DTOExplanationProperty $Assessment 'AssessmentType'
    $rulesVersion = Get-DTOExplanationProperty $Assessment 'RulesVersion'
    if ($null -eq $schema -or $schema.GetType().FullName -notin @(
            'System.Byte','System.SByte','System.Int16','System.UInt16','System.Int32','System.UInt32','System.Int64','System.UInt64'
        ) -or $schema -ne 1 -or
        $product -isnot [string] -or $product -cne 'DeviceCare' -or
        $assessmentType -isnot [string] -or $assessmentType -cne 'ReadOnlyRecommendations' -or
        $rulesVersion -isnot [string] -or $rulesVersion -cne 'dto-0.2' -or
        $authorized -isnot [bool] -or $authorized -ne $false) {
        throw 'DTO.InvalidExplanationInput.Assessment'
    }

    $items = Get-DTOExplanationProperty $Assessment 'Findings'
    if ($items -isnot [Array] -or $items.Rank -ne 1 -or $items.Count -ne 2) {
        throw 'DTO.InvalidExplanationInput.Findings'
    }
    $thresholds = Get-DTOExplanationProperty $Assessment 'Thresholds'
    $minimum = ConvertTo-DTOExplanationNumber (Get-DTOExplanationProperty $thresholds 'MinimumDiskFreeGiB')
    $maximum = ConvertTo-DTOExplanationNumber (Get-DTOExplanationProperty $thresholds 'MaximumMemoryUsedPercent')
    if ($null -eq $minimum -or $minimum -lt 1 -or $minimum -gt 1024) { $minimum = $null }
    if ($null -eq $maximum -or $maximum -lt 1 -or $maximum -gt 99) { $maximum = $null }

    $findings = New-Object 'System.Collections.Generic.List[object]'
    foreach ($id in @('memory','system-disk')) {
        $matches = @($items | Where-Object {
            $identity = Get-DTOExplanationProperty $_ 'Id'
            $identity -is [string] -and $identity -ceq $id
        })
        if ($matches.Count -ne 1) { throw 'DTO.InvalidExplanationInput.FindingIdentity' }
        $state = Get-DTOExplanationProperty $matches[0] 'State'
        if ($state -isnot [string] -or @('Observed','Review','Unknown') -cnotcontains $state) {
            throw 'DTO.InvalidExplanationInput.FindingState'
        }
        $observed = $null
        if ($state -cne 'Unknown') {
            $observed = ConvertTo-DTOExplanationNumber (Get-DTOExplanationProperty $matches[0] 'Observed')
            if ($null -eq $observed -or ($id -ceq 'memory' -and $observed -gt 100)) {
                throw 'DTO.InvalidExplanationInput.FindingValue'
            }
        }
        $findings.Add([pscustomobject][ordered]@{
            id = $id
            state = $state
            observed = $observed
            units = $(if ($id -ceq 'memory') { 'percent' } else { 'GiB' })
            threshold = $(if ($id -ceq 'memory') { $maximum } else { $minimum })
        })
    }

    $at = Get-DTOExplanationProperty $Assessment 'CollectedAtUtc'
    $parsed = [DateTimeOffset]::MinValue
    if ($at -isnot [string] -or
        $at -cnotmatch '\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?Z\z' -or
        -not [DateTimeOffset]::TryParse($at, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        $at = $null
    }
    $inputRecord = [pscustomobject][ordered]@{
        schema_version = 1
        product = 'DeviceCare'
        rules_version = 'dto-0.2'
        observed_at_utc = $at
        maintenance_authorized = $false
        findings = @($findings.ToArray())
    }
    $inputJson = $inputRecord | ConvertTo-Json -Depth 6 -Compress
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($inputJson)))).Replace('-','').ToLowerInvariant()
    } finally { $hasher.Dispose() }
    [pscustomobject][ordered]@{SchemaVersion=1; InputJson=$inputJson; InputSha256=$hash}
}

function Get-DTOExplanationNextCheckId {
    param([string]$Id, [string]$State)
    if ($State -ceq 'Unknown') { return 'retry_observation' }
    if ($State -ceq 'Observed') { return 'observe_if_symptoms' }
    if ($Id -ceq 'memory') { return 'inspect_memory_workload' }
    return 'review_storage_usage'
}

function Get-DTOExplanationNextCheckText {
    param([string]$Id)
    switch -CaseSensitive ($Id) {
        'inspect_memory_workload' { return 'Review memory use in Task Manager while the symptoms occur, and compare it with a later observation. This snapshot does not identify which application is responsible.' }
        'review_storage_usage' { return 'Review the storage usage categories and available space before deciding on further work. This explanation does not select files or run cleanup.' }
        'retry_observation' { return 'Repeat this observation in an authorized environment and review any remaining collection problem.' }
        'observe_if_symptoms' { return 'If symptoms continue, compare a later observation taken during the problem. This result alone does not establish overall device health.' }
        default { throw 'DTO.InvalidExplanationResponse.NextCheck' }
    }
}

function Get-DTOExplanationLocalMeaning {
    param($Finding)
    $memory = $Finding.id -ceq 'memory'
    $label = if ($memory) { 'Memory use' } else { 'Available system-drive space' }
    if ($Finding.state -ceq 'Unknown') {
        return ($label + ' could not be assessed because this snapshot has no usable measurement. An unknown result is not a pass.')
    }
    $value = ([double]$Finding.observed).ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)
    $meaning = $label + ' was recorded as ' + $value + ' ' + $Finding.units + '. '
    if ($null -eq $Finding.threshold) {
        $meaning += 'The selected threshold is unavailable in this assessment, so this explanation preserves the recorded ' + $Finding.state + ' result. '
    } else {
        $threshold = ([double]$Finding.threshold).ToString('R', [Globalization.CultureInfo]::InvariantCulture)
        if ($memory -and $Finding.state -ceq 'Review') {
            $meaning += 'The unrounded measurement met or exceeded the selected ' + $threshold + ' percent review threshold. '
        } elseif ($memory) {
            $meaning += 'The unrounded measurement was below the selected ' + $threshold + ' percent review threshold. '
        } elseif ($Finding.state -ceq 'Review') {
            $meaning += 'The unrounded measurement was below the selected ' + $threshold + ' GiB minimum. '
        } else {
            $meaning += 'The unrounded measurement was at or above the selected ' + $threshold + ' GiB minimum. '
        }
    }
    if ($memory) { return ($meaning + 'This observation does not identify the workload or the cause of any performance problem.') }
    return ($meaning + 'This observation does not establish disk hardware condition or identify files that can be removed.')
}

function Get-DTODeviceCareExplanation {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowNull()]$Assessment, [AllowNull()]$AiResponse)

    # Invalid source evidence throws; an unusable optional response falls back locally.
    $request = New-DTODeviceCareExplanationRequest -Assessment $Assessment
    $inputRecord = $request.InputJson | ConvertFrom-Json
    $results = New-Object 'System.Collections.Generic.List[object]'
    foreach ($finding in $inputRecord.findings) {
        $nextCheck = Get-DTOExplanationNextCheckId $finding.id $finding.state
        $results.Add([pscustomobject][ordered]@{
            Id = $finding.id
            State = $finding.state
            Meaning = Get-DTOExplanationLocalMeaning $finding
            NextCheckId = $nextCheck
            NextCheck = Get-DTOExplanationNextCheckText $nextCheck
        })
    }
    $review = @($inputRecord.findings | Where-Object { $_.state -ceq 'Review' }).Count
    $unknown = @($inputRecord.findings | Where-Object { $_.state -ceq 'Unknown' }).Count
    $summary = if ($unknown -eq 2) {
        'Neither memory use nor system-drive space could be assessed from this snapshot. Repeat the unavailable observations before deciding what to investigate.'
    } elseif ($review -eq 2) {
        'Both memory use and system-drive free space met the selected review rules. Inspect the workload and storage usage to learn more; these observations do not identify a cause.'
    } elseif ($review -eq 1 -and $unknown -eq 1) {
        'One result needs review and the other is unknown. Investigate the recorded review finding and repeat the unavailable observation before drawing wider conclusions.'
    } elseif ($review -eq 1) {
        'One result needs review; the other is within the selected thresholds. Start with the finding marked for review and relate it to the symptoms you are experiencing.'
    } elseif ($unknown -eq 1) {
        'One result is within the selected thresholds and the other is unknown. Repeat the unavailable observation; the available result does not resolve the missing evidence.'
    } else {
        'The recorded memory use and system-drive free space did not meet the selected review rules. Ongoing symptoms still need their own investigation.'
    }
    $result = [pscustomobject][ordered]@{
        SchemaVersion = 1
        Source = 'LocalRules'
        AiStatus = 'NotRequested'
        InputSha256 = $request.InputSha256
        Summary = $summary
        Findings = @($results.ToArray())
        Limitations = "This is a one-moment snapshot of memory use and system-drive free space only. Displayed values are rounded; DeviceCare's recorded states use unrounded measurements. Unknown is not a pass, and a threshold is not a diagnosis. Update status, restart needs, malware, services, and repair results were not checked. This explanation does not authorize or perform maintenance."
    }
    if (-not $PSBoundParameters.ContainsKey('AiResponse')) { return $result }
    $result.AiStatus = 'Rejected'
    try {
        Assert-DTOExplanationRecord $AiResponse @('InputSha256','ModelResponse')
        $responseHash = Get-DTOExplanationProperty $AiResponse 'InputSha256'
        if ($responseHash -isnot [string] -or $responseHash -cne $request.InputSha256) {
            throw 'DTO.InvalidExplanationResponse.Source'
        }
        $response = Get-DTOExplanationProperty $AiResponse 'ModelResponse'
        Assert-DTOExplanationRecord $response @('summary','findings')
        $responseSummary = Get-DTOExplanationProperty $response 'summary'
        Assert-DTOExplanationText $responseSummary 600
        $responseFindings = Get-DTOExplanationProperty $response 'findings'
        if ($responseFindings -isnot [Array] -or $responseFindings.Rank -ne 1 -or $responseFindings.Count -ne 2) {
            throw 'DTO.InvalidExplanationResponse.Findings'
        }
        $meanings = @{}
        foreach ($responseFinding in $responseFindings) {
            Assert-DTOExplanationRecord $responseFinding @('id','state','explanation','next_check_id')
            $id = Get-DTOExplanationProperty $responseFinding 'id'
            if ($id -isnot [string] -or @('memory','system-disk') -cnotcontains $id -or $meanings.ContainsKey($id)) {
                throw 'DTO.InvalidExplanationResponse.FindingIdentity'
            }
            $source = @($result.Findings | Where-Object { $_.Id -ceq $id })[0]
            $state = Get-DTOExplanationProperty $responseFinding 'state'
            $nextCheck = Get-DTOExplanationProperty $responseFinding 'next_check_id'
            if ($state -isnot [string] -or $state -cne $source.State -or
                $nextCheck -isnot [string] -or $nextCheck -cne $source.NextCheckId) {
                throw 'DTO.InvalidExplanationResponse.FindingStateOrNextCheck'
            }
            $meaning = Get-DTOExplanationProperty $responseFinding 'explanation'
            Assert-DTOExplanationText $meaning 900
            $meanings[$id] = $meaning.Trim()
        }
        # Apply only after every field validates; partial responses cannot change the fallback.
        $result.Summary = $responseSummary.Trim()
        foreach ($finding in $result.Findings) { $finding.Meaning = $meanings[$finding.Id] }
        $result.Source = 'AI'
        $result.AiStatus = 'Accepted'
    } catch {
        # No raw provider or validation error is exposed in the user-facing report.
    }
    return $result
}
