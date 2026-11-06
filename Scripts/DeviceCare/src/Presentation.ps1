#Requires -Version 5.1
# Presentation only: fixed local assets, projected fields, no file writes or process launch.
function ConvertTo-DTODeviceCareHtml {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Assessment)
    if ((Get-DTOProperty $Assessment 'SchemaVersion') -ne 1 -or
        (Get-DTOProperty $Assessment 'Product') -cne 'DeviceCare' -or
        (Get-DTOProperty $Assessment 'AssessmentType') -cne 'ReadOnlyRecommendations' -or
        (Get-DTOProperty $Assessment 'MaintenanceAuthorized') -isnot [bool] -or
        (Get-DTOProperty $Assessment 'MaintenanceAuthorized') -ne $false) { throw 'DTO.InvalidAssessment' }
    $items=@(Get-DTOProperty $Assessment 'Findings')
    if($items.Count -ne 2) { throw 'DTO.InvalidFindings' }
    $rows=New-Object 'System.Collections.Generic.List[string]'
    $projected=New-Object 'System.Collections.Generic.List[object]'
    $counts=@{Observed=0;Review=0;Unknown=0}
    foreach($id in @('memory','system-disk')) {
        $matches=@($items|Where-Object{(Get-DTOProperty $_ 'Id') -ceq $id})
        if($matches.Count -ne 1){throw 'DTO.InvalidFindingIdentity'}
        $f=$matches[0];$state=Get-DTOProperty $f 'State'
        if($state -isnot [string] -or @('Observed','Review','Unknown') -cnotcontains $state){throw 'DTO.InvalidFindingState'}
        $explanation=Get-DTOProperty $f 'Explanation'
        if($explanation -isnot [string] -or $explanation.Length -gt 500){throw 'DTO.InvalidFindingText'}
        $value=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $f 'Observed')
        if($state -ne 'Unknown' -and $null -eq $value){throw 'DTO.InvalidFindingValue'}
        if($id -eq 'memory' -and $null -ne $value -and $value -gt 100){throw 'DTO.InvalidFindingValue'}
        if($state -eq 'Unknown'){$value=$null}
        $label=if($id -eq 'memory'){'Memory use'}else{'System-drive free space'}
        $units=if($id -eq 'memory'){'percent'}else{'GiB'}
        $display=if($null -eq $value){'Not available'}else{$value.ToString('0.##',[Globalization.CultureInfo]::InvariantCulture)+' '+$units}
        $counts[$state]++
        $safe=[Net.WebUtility]::HtmlEncode($explanation)
        $rows.Add('<tr><th scope="row">'+$label+'</th><td><strong>'+$state+'</strong></td><td>'+$display+'</td><td>'+$safe+'</td></tr>')
        $projected.Add([pscustomobject]@{Id=$id;State=$state;Explanation=$explanation;Observed=$value;Units=$units})
    }
    $root=Split-Path $PSScriptRoot -Parent
    $asset=[IO.File]::ReadAllBytes((Join-Path $root 'brand/dto-header-monogram.svg'))
    $hasher=[Security.Cryptography.SHA256]::Create()
    try{$hash=([BitConverter]::ToString($hasher.ComputeHash($asset))).Replace('-','').ToLowerInvariant()}finally{$hasher.Dispose()}
    if($hash -cne 'f8f6a4dcbf4972ed4d1302dcba0e2191bd966053a5ad0dabf313de242c1e61e3'){throw 'DTO.BrandAssetMismatch'}
    $logo=[Convert]::ToBase64String($asset)
    # Preserve a valid original observation time; never invent a current timestamp.
    $at=Get-DTOProperty $Assessment 'CollectedAtUtc'
    $parsed=[DateTimeOffset]::MinValue
    if($at -isnot [string] -or $at -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?Z$' -or
        -not [DateTimeOffset]::TryParse($at,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$parsed)){$at=$null}
    $thresholds=Get-DTOProperty $Assessment 'Thresholds'
    $min=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $thresholds 'MinimumDiskFreeGiB')
    $max=ConvertTo-DTOFiniteDecimal (Get-DTOProperty $thresholds 'MaximumMemoryUsedPercent')
    if($null -eq $min -or $min -lt 1 -or $min -gt 1024){$min=$null}
    if($null -eq $max -or $max -lt 1 -or $max -gt 99){$max=$null}
    $metadata='Observed at: '+$(if($null -eq $at){'Unknown'}else{$at})+'. Disk minimum: '+$(if($null -eq $min){'Unknown'}else{$min.ToString([Globalization.CultureInfo]::InvariantCulture)+' GiB'})+'. Memory review threshold: '+$(if($null -eq $max){'Unknown'}else{$max.ToString([Globalization.CultureInfo]::InvariantCulture)+' percent'})+'.'
    # Deliberately omit caller-added properties and real endpoint identifiers.
    $view=[ordered]@{SchemaVersion=1;Product='DeviceCare';Version='0.2.0-dto-preview';CollectedAtUtc=$at;Thresholds=[ordered]@{MinimumDiskFreeGiB=$min;MaximumMemoryUsedPercent=$max};MaintenanceAuthorized=$false;Findings=@($projected.ToArray())}
    $detail=[Net.WebUtility]::HtmlEncode(($view|ConvertTo-Json -Depth 6))
    $template=[IO.File]::ReadAllText((Join-Path $root 'brand/report.html'))
    $values=@{METADATA=[Net.WebUtility]::HtmlEncode($metadata);LOGO=$logo;ROWS=($rows -join "`n");OBSERVED=[string]$counts.Observed;REVIEW=[string]$counts.Review;UNKNOWN=[string]$counts.Unknown;DETAIL=$detail}
    [regex]::Replace($template,'\{\{(METADATA|LOGO|ROWS|OBSERVED|REVIEW|UNKNOWN|DETAIL)\}\}',[Text.RegularExpressions.MatchEvaluator]{param($match) $values[$match.Groups[1].Value]})
}
