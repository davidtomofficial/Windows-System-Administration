#Requires -Version 5.1
# Returns an offline HTML string. No file, network or process operations.
function ConvertTo-DTODeviceCareExplainedHtml {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Assessment, $AiResponse)

    # Validate before the legacy renderer reads caller-owned objects. Its property
    # accessor predates this module's NoteProperty-only input contract.
    $request = New-DTODeviceCareExplanationRequest -Assessment $Assessment
    $record = $request.InputJson | ConvertFrom-Json
    $sourceFindings = Get-DTOExplanationProperty $Assessment 'Findings'
    $reportFindings = New-Object 'System.Collections.Generic.List[object]'
    foreach ($finding in $record.findings) {
        $source = @($sourceFindings | Where-Object {
            (Get-DTOExplanationProperty $_ 'Id') -ceq $finding.id
        })[0]
        $reportFindings.Add([pscustomobject]@{
            Id = $finding.id
            State = $finding.state
            # Original finding prose is local report evidence, never model input.
            Explanation = Get-DTOExplanationProperty $source 'Explanation'
            Observed = $finding.observed
            Units = $finding.units
        })
    }
    # Keep the accepted original string: newer ConvertFrom-Json versions may
    # convert its parsed representation into a DateTime automatically.
    $observedAt = if ($null -ne $record.observed_at_utc) {
        Get-DTOExplanationProperty $Assessment 'CollectedAtUtc'
    } else { $null }
    $reportAssessment = [pscustomobject]@{
        SchemaVersion = 1
        Product = 'DeviceCare'
        AssessmentType = 'ReadOnlyRecommendations'
        RulesVersion = 'dto-0.2'
        MaintenanceAuthorized = $false
        CollectedAtUtc = $observedAt
        Thresholds = [pscustomobject]@{
            MaximumMemoryUsedPercent = $record.findings[0].threshold
            MinimumDiskFreeGiB = $record.findings[1].threshold
        }
        Findings = @($reportFindings.ToArray())
    }
    # The original renderer sees only fresh, selected NoteProperty records.
    $html = ConvertTo-DTODeviceCareHtml -Assessment $reportAssessment
    $parameters = @{ Assessment = $reportAssessment }
    if ($PSBoundParameters.ContainsKey('AiResponse')) { $parameters.AiResponse = $AiResponse }
    $explanation = Get-DTODeviceCareExplanation @parameters
    $sourceLabel = if ($explanation.Source -ceq 'AI') { 'AI explanation' } else { 'Local explanation' }
    $statusText = if ($explanation.AiStatus -ceq 'Rejected') {
        'The supplied AI explanation could not be verified for this assessment. The local explanation is shown.'
    } elseif ($explanation.Source -ceq 'AI') {
        'AI wording can contain mistakes. Compare it with the original findings and measurements above.'
    } else {
        'Generated locally from the recorded findings. No AI request was made by this report.'
    }
    $parts = New-Object 'System.Collections.Generic.List[string]'
    $parts.Add('<section class="notice" aria-labelledby="explanation-heading" style="margin-top:1.5rem">')
    $parts.Add('<p class="eyebrow">'+[Net.WebUtility]::HtmlEncode($sourceLabel)+'</p>')
    $parts.Add('<h2 id="explanation-heading">What these results mean</h2>')
    $parts.Add('<p>'+[Net.WebUtility]::HtmlEncode($explanation.Summary)+'</p>')
    foreach ($finding in $explanation.Findings) {
        $label = if ($finding.Id -ceq 'memory') { 'Memory use' } else { 'System-drive free space' }
        $parts.Add('<article aria-labelledby="explanation-'+$finding.Id+'" style="margin-top:1.25rem">')
        $parts.Add('<h3 id="explanation-'+$finding.Id+'" style="font-size:1.08rem;margin-bottom:.3rem">'+$label+' <span style="font-weight:400">('+[Net.WebUtility]::HtmlEncode($finding.State)+')</span></h3>')
        $parts.Add('<p>'+[Net.WebUtility]::HtmlEncode($finding.Meaning)+'</p>')
        $parts.Add('<p><strong>Next check:</strong> '+[Net.WebUtility]::HtmlEncode($finding.NextCheck)+'</p></article>')
    }
    $parts.Add('<p style="margin-top:1.25rem"><strong>Coverage:</strong> '+[Net.WebUtility]::HtmlEncode($explanation.Limitations)+'</p>')
    $parts.Add('<p style="font-size:.9rem">'+[Net.WebUtility]::HtmlEncode($statusText)+'</p></section>')
    # Fail explicitly if the source report no longer has this single integration point.
    $marker = '<details><summary>Show structured evidence</summary>'
    $position = $html.IndexOf($marker, [StringComparison]::Ordinal)
    if ($position -lt 0 -or $html.IndexOf($marker, $position + $marker.Length, [StringComparison]::Ordinal) -ge 0) {
        throw 'DTO.ExplanationReportIntegrationPointChanged'
    }
    $html.Insert($position, ($parts -join "`n") + "`n")
}
