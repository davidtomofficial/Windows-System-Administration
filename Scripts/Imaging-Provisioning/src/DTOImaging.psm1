#Requires -Version 5.1
# Copyright (c) 2026 David Tom. Personal development preview; not deployment authority.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DTOField($InputObject, [string]$Name) {
    if ($null -eq $InputObject) { return $null }
    $p = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $p -and $p.MemberType -in @('NoteProperty','Property')) { return $p.Value }
    return $null
}
function Test-DTOText($Value) {
    return ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value.Length -le 256 -and $Value -notmatch '[\p{Cc}\p{Cf}]')
}
function Assert-DTOWindows {
    if ($env:OS -ne 'Windows_NT') { throw 'DTO.WindowsRequired' }
}
function Invoke-DTOCimQuery([string]$ClassName,[string[]]$Properties,[int]$Timeout) {
    Get-CimInstance -ClassName $ClassName -Property $Properties -OperationTimeoutSec $Timeout -ErrorAction Stop
}
function Get-DTOSection {
    param([string]$ClassName,[string[]]$Properties,[int]$Limit=1,[int]$Timeout=5,[switch]$Services)
    $rows = New-Object 'Collections.Generic.List[object]'
    $seen = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $c = @{ Enumerated=0; Inspected=0; Invalid=$false; Duplicate=$false; Failed=$false; Bytes=1024; ByteLimit=$false }
    try {
        Invoke-DTOCimQuery $ClassName $Properties $Timeout | Select-Object -First ($Limit+1) | ForEach-Object {
            $c.Enumerated++
            if ($c.Enumerated -le $Limit) {
                $c.Inspected++
                try {
                    $row = [ordered]@{}; $valid = $true
                    foreach ($name in $Properties) {
                        $v = Get-DTOField $_ $name
                        if (-not (Test-DTOText $v)) { $valid = $false }
                        $row[$name] = $v
                    }
                    if ($Services -and ($row.State -cnotin @('Stopped','Start Pending','Stop Pending','Running','Continue Pending','Pause Pending','Paused','Unknown') -or
                        $row.StartMode -cnotin @('Boot','System','Auto','Manual','Disabled'))) { $valid = $false }
                    if (-not $valid) { $c.Invalid=$true }
                    elseif ($Services -and -not $seen.Add($row.Name)) { $c.Duplicate=$true }
                    else {
                        $record = [pscustomobject]$row
                        $cost = [Text.Encoding]::UTF8.GetByteCount(($record | ConvertTo-Json -Compress -Depth 3))+256
                        if ($c.Bytes+$cost -gt 131072) { $c.ByteLimit=$true }
                        else { $rows.Add($record); $c.Bytes+=$cost }
                    }
                } catch { $c.Invalid=$true }
            }
        }
    } catch { $c.Failed=$true }
    $limited = $c.Enumerated -gt $Limit
    $complete = -not ($limited -or $c.Failed -or $c.Invalid -or $c.Duplicate -or $c.ByteLimit) -and $c.Enumerated -gt 0
    $status = if ($complete) {'Complete'} elseif ($c.Failed -and $c.Enumerated -eq 0) {'Unavailable'} elseif ($c.Enumerated -eq 0) {'NoData'} else {'Partial'}
    $reason = if ($limited) {'RecordLimit'} elseif ($c.Failed) {'QueryFailed'} elseif ($c.Invalid) {'InvalidRecord'} elseif ($c.Duplicate) {'DuplicateName'} elseif ($c.ByteLimit) {'ByteLimit'} elseif ($c.Enumerated -eq 0) {'NoRows'} else {$null}
    [pscustomobject]@{ Source=$ClassName; Status=$status; Reason=$reason; Records=@($rows.ToArray());
        EnumeratedCount=$c.Enumerated; InspectedCount=$c.Inspected; RecordLimit=$Limit; RecordByteLimit=131072;
        EnumerationComplete=(-not $limited -and -not $c.Failed); CollectionComplete=$complete }
}
function Get-DTOProduct {
    $p = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../brand/product.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($p.productId -cne 'dto-imaging-provisioning' -or $p.productName -cne 'DTO Imaging & Provisioning' -or
        $p.websiteUrl -cne 'https://davidtomofficial.com/' -or $p.contactUrl -cne 'https://davidtomofficial.com/#contact' -or
        $p.supportEmail -cne 'david.tom@davidtomofficial.com' -or $p.version -cne '0.2.0') { throw 'DTO.InvalidProductMetadata' }
    $p
}
function Get-DTOWorkstationSnapshot {
    [CmdletBinding()]
    param([switch]$IncludeComputerName,[ValidateRange(1,30)][int]$OperationTimeoutSec=5)
    Assert-DTOWindows
    $product=Get-DTOProduct
    $sections=@(
        Get-DTOSection 'Win32_OperatingSystem' @('Caption','Version','OSArchitecture') 1 $OperationTimeoutSec
        Get-DTOSection 'Win32_ComputerSystem' @('Manufacturer','Model') 1 $OperationTimeoutSec
        Get-DTOSection 'Win32_BIOS' @('SMBIOSBIOSVersion') 1 $OperationTimeoutSec
        Get-DTOSection 'Win32_Processor' @('Name') 16 $OperationTimeoutSec
    )
    $result=[ordered]@{ SchemaVersion=2; Product=$product.productName; Version=$product.version;
        AssessmentType='ReadOnlyLocalSnapshot'; CollectedAtUtc=[DateTime]::UtcNow.ToString('o');
        ComputerNameIncluded=[bool]$IncludeComputerName; Sections=$sections;
        CollectionComplete=(@($sections | Where-Object {-not $_.CollectionComplete}).Count -eq 0);
        DeploymentAccepted=$false; Notice='Review before sharing. Hardware and OS details can still be sensitive.' }
    if ($IncludeComputerName) {
        $name=$env:COMPUTERNAME
        if (Test-DTOText $name) { $result['ComputerName']=$name }
        else { $result['ComputerName']=$null; $result['CollectionComplete']=$false }
    }
    [pscustomobject]$result
}
function Get-DTOServiceSnapshot {
    [CmdletBinding()]
    param([ValidateRange(1,1024)][int]$MaximumRecords=1024,[ValidateRange(1,30)][int]$OperationTimeoutSec=5)
    Assert-DTOWindows
    $section=Get-DTOSection 'Win32_Service' @('Name','DisplayName','State','StartMode') $MaximumRecords $OperationTimeoutSec -Services
    [pscustomobject]@{ SchemaVersion=1; Product='DTO Imaging & Provisioning'; Version='0.2.0';
        CollectedAtUtc=[DateTime]::UtcNow.ToString('o'); Section=$section;
        HealthAssessed=$false; OwnershipVerified=$false; ChangesAllowed=$false;
        Notice='Service names and states are observations only. Stopped does not mean faulty; partial collection cannot establish absence.' }
}
function Invoke-DTOImageQuery([string]$Path,[int]$Index) {
    if ($Index -gt 0) { Dism\Get-WindowsImage -ImagePath $Path -Index $Index -ErrorAction Stop }
    else { Dism\Get-WindowsImage -ImagePath $Path -ErrorAction Stop }
}
function Get-DTOImageReview {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ImagePath,[ValidateRange(0,65535)][int]$Index=0,[switch]$ComputeSha256)
    Assert-DTOWindows
    # No UNC, device path, alternate stream, relative path, network drive or reparse traversal.
    if ($ImagePath -notmatch '^[A-Za-z]:\\' -or $ImagePath.Substring(2).Contains(':')) { throw 'DTO.LocalImagePathRequired' }
    try {
        $file=Get-Item -LiteralPath $ImagePath -Force -ErrorAction Stop
        if ($file -isnot [IO.FileInfo] -or $file.Extension -ine '.wim' -or $file.Length -le 0) { throw 'invalid' }
        $drive=New-Object IO.DriveInfo ($file.Directory.Root.FullName)
        if ($drive.DriveType -notin @([IO.DriveType]::Fixed,[IO.DriveType]::Removable)) { throw 'drive' }
        $node=$file
        while ($null -ne $node) {
            if (($node.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'reparse' }
            $node=if ($node -is [IO.FileInfo]) {$node.Directory} else {$node.Parent}
        }
    } catch { throw 'DTO.InvalidLocalWim' }
    $beforeLength=$file.Length; $beforeWrite=$file.LastWriteTimeUtc.Ticks
    $records=New-Object 'Collections.Generic.List[object]'
    $seen=New-Object 'Collections.Generic.HashSet[int]'
    $c=@{Count=0;Invalid=$false;Failed=$false}; $hash=$null; $hashState='NotRequested'
    try {
        Invoke-DTOImageQuery $file.FullName $Index | Select-Object -First 65 | ForEach-Object {
            $c.Count++
            if ($c.Count -le 64) {
                $i=Get-DTOField $_ 'ImageIndex'; $name=Get-DTOField $_ 'ImageName'
                if (($i -isnot [int] -and $i -isnot [uint32] -and $i -isnot [long]) -or $i -lt 1 -or $i -gt 65535 -or -not (Test-DTOText $name) -or
                    ($Index -gt 0 -and $Index -ne $i) -or -not $seen.Add($i)) { $c.Invalid=$true }
                else { $records.Add([pscustomobject]@{Index=$i; Name=$name}) }
            }
        }
    } catch { $c.Failed=$true }
    if ($ComputeSha256) {
        try { $hash=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash; $hashState='Computed' }
        catch { $hashState='Unavailable' }
    }
    $file.Refresh()
    $unchanged=$file.Exists -and $file.Length -eq $beforeLength -and $file.LastWriteTimeUtc.Ticks -eq $beforeWrite
    $status=if (-not $unchanged) {'ChangedDuringRead'} elseif ($c.Failed -and $records.Count -eq 0) {'Unavailable'} elseif ($c.Failed) {'Partial'} elseif ($c.Invalid -or $c.Count -gt 64) {'Partial'} elseif ($c.Count -eq 0) {'NoData'} else {'Observed'}
    if (-not $unchanged) { $hash=$null; $hashState='Invalidated' }
    [pscustomobject]@{ SchemaVersion=1; Product='DTO Imaging & Provisioning'; Version='0.2.0';
        CollectedAtUtc=[DateTime]::UtcNow.ToString('o'); Status=$status; RequestedIndex=$Index;
        Images=@($records.ToArray()); FileBytes=$beforeLength; SourceMetadataUnchanged=$unchanged;
        Sha256=$hash; HashStatus=$hashState; PathIncluded=$false; DeploymentAccepted=$false;
        Notice='Metadata inspection only. No target disk, mount, apply or partition operation. DISM may write diagnostic logs. Image names may be sensitive; review before sharing. Metadata stability is not a concurrency lock or authenticity proof.' }
}
function ConvertTo-DTOReviewHtml {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Review)
    $product=Get-DTOProduct
    $encoded=[Net.WebUtility]::HtmlEncode(($Review | ConvertTo-Json -Depth 12))
    @"
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>DTO Imaging &amp; Provisioning - local review</title>
<style>body{font:17px/1.6 'Segoe UI',Arial,sans-serif;background:#F8F9FB;color:#0F2747;max-width:72rem;margin:0 auto;padding:1.5rem}header{border-bottom:3px solid #D4A574}h1{line-height:1.2}section{background:#E6ECF2;padding:1rem;margin-top:1.5rem}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:14px}a{color:#0F2747;text-decoration:underline}a:focus-visible{outline:3px solid #0F2747;outline-offset:4px}@media(forced-colors:active){body,section{background:Canvas;color:CanvasText}a{color:LinkText}a:focus-visible{outline-color:Highlight}}</style></head><body>
<header><p>DAVID TOM OFFICIAL / PERSONAL DEVELOPMENT PREVIEW</p><h1>DTO Imaging &amp; Provisioning</h1><p>Version $($product.version) - Local observation report</p></header>
<p><strong>Not an approval to deploy.</strong> Incomplete evidence stays incomplete. Review this report for sensitive details before sharing.</p>
<section aria-label="Collected evidence"><h2>Observed evidence</h2><pre>$encoded</pre></section>
<footer><p><a href="https://davidtomofficial.com/#contact">David Tom - project contact</a></p><p>No telemetry, automatic upload, external fonts, scripts or images. No commercial support promise.</p></footer></body></html>
"@
}
Export-ModuleMember -Function Get-DTOProduct,Get-DTOWorkstationSnapshot,Get-DTOServiceSnapshot,Get-DTOImageReview,ConvertTo-DTOReviewHtml
