Using namespace System.Collections.Generic
Using namespace System.IO
Using namespace System.Text

function Get-WindowsSpotlightImageFile {

    Param(
        [Parameter()][Int32]$MinByteSize = 0,
        [Parameter()][Int32]$MaxByteSize
    )

    [String]$spotlightPath = "$env:LocalAppData\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\"

    [StringBuilder]$sizeFilter = [StringBuilder]::new('($MinByteSize -le $_.Length)')
    If ($PSBoundParameters.ContainsKey('MaxByteSize')) {
        Out-Null -InputObject ($sizeFilter.Append(' -and ($_.Length -le $MaxByteSize)'))
    }

    [Hashtable]$matchesFilter = @{
        FilterScript = [ScriptBlock]::Create("$sizeFilter")
    }

    Get-ChildItem -File -Path $spotlightPath | Where-Object @matchesFilter
}