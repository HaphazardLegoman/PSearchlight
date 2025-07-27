function Export-WindowsSpotlightImageFile {

    Param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -IsValid -Path $_ })]
        [String]$Destination,
        [Parameter()]
        [ValidateSet('Landscape', 'Portrait', 'Square')]
        [String[]]$Orientation = @('Landscape', 'Portrait', 'Square'),
        [Parameter()][Int32]$MinByteSize = 10000,
        [Parameter()][Int32]$MaxByteSize
    )

    Assert-Directory -Path $Destination

    $selectedImage = Foreach ($c in 'Get-WindowsSpotlightImageFile') {
        [Hashtable]$sizeFilter = $PSBoundParameters | Select-BoundParameter -ReferenceCommand $c
        & $c @sizeFilter
    }
    $filteredImage = $selectedImage | Open-Bitmap | Where-Object -FilterScript { $Orientation -contains $(Measure-BitmapOrientation -InputObject $_) }

    Foreach ($c in (Copy-Item -PassThru -Path $filteredImage -Destination $Destination)) {
        Rename-Item -Force -Path $c.FullName -NewName [IO.Path]::ChangeExtension('.jpg')
    }
}