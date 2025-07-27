Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.Drawing
Using namespace System.IO
Using namespace System.Management.Automation

function Open-Bitmap {

    [CmdletBinding()] [OutputType([Bitmap])]

    [SuppressMessageAttribute('PSReviewUnusedParameter', '', Target = 'FilePath', Justification = 'This parameter is being used in a manner or scope that PSScriptAnalyzer cannot see.')]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
                Try {
                    $givenPath = $_
                    $resolvedPath = Resolve-Path -Path $givenPath -ErrorAction Stop
                    If (Get-Item -Path $_ | Select-Object -ExpandProperty PSIsContainer) {
                        Throw [ValidationMetadataException]::new("`"$givenPath`" is not a file.")
                    } Else {
                        $workloadTag = [Path]::GetFileNameWithoutExtension($givenPath)
                        Try {
                            Set-Variable -PassThru -Scope 1 -Name "Bitmap_$workloadTag" -Value $([Bitmap]::FromFile($resolvedPath)) | ForEach-Object -Process {[Boolean]$_}
                        } Catch {
                            Throw [ValidationMetadataException]::new("`"$givenPath`" could not be opened as a bitmap object.", $_.Exception)
                        }
                    }
                } Catch [ItemNotFoundException] {
                    Throw [ItemNotFoundException]::new("The file `"$givenPath`" does not exist.", $_.Exception)
                }
            })]
        [String[]]$FilePath
    )

    Process {
        Foreach ($f in $FilePath) {
            $validationWorkloadId = "Bitmap_$([IO.Path]::GetFileNameWithoutExtension($f))"
            Get-Variable -ValueOnly -Name $validationWorkloadId
        }
    }
}

Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.Drawing
Using namespace System.IO
Using namespace System.Management.Automation

function Open-BitmapAlt {
#TODO : test performance across these variants
    [CmdletBinding()] [OutputType([Bitmap])]

    [SuppressMessageAttribute('PSReviewUnusedParameter', '', Target = 'FilePath', Justification = 'This parameter is being used in a manner or scope that PSScriptAnalyzer cannot see.')]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
                Try {
                    $givenPath = $_
                    $resolvedPath = Resolve-Path -Path $givenPath -ErrorAction Stop
                    If (-not (Get-Item -Path $_ | Select-Object -ExpandProperty PSIsContainer)) { $true } Else {
                        Throw [ValidationMetadataException]::new("`"$givenPath`" is not a file.")
                    } 
                } Catch [ItemNotFoundException] {
                    Throw [ItemNotFoundException]::new("The file `"$givenPath`" does not exist.", $_.Exception)
                }
            })]
        [String[]]$FilePath
    )

    Process {
        Foreach ($f in $FilePath) {
            Try { [Bitmap]::FromFile($f) } Catch {
                Write-Error [ValidationMetadataException]::new("`"$f`" could not be opened as a bitmap object.", $_.Exception)
            } 
        }
    }
}

function Test-ValidateScript {

    [CmdletBinding()] [OutputType([String])]

    [SuppressMessageAttribute('PSReviewUnusedParameter', '', Target = 'FilePath', Justification = 'This parameter is being used in a manner or scope that PSScriptAnalyzer cannot see.')]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
                $i = $_
                If ($_ -like 'a*') {
                    Set-Variable -PassThru -Scope 1 -Name "valString$([io.path]::GetRandomFileName())" -Value "${_}_validated" | ForEach-Object {[Boolean]$_}
                } Else {
                    Throw "I don't like $i"
                }
            })]
        [String[]]$InputString
    )

    Process { Get-Variable -Name 'valString*' | ForEach-Object {
        $_.Value
        Remove-Variable -Name $_.Name
    } }
}

function Test-ValidateScript {

    [CmdletBinding()] [OutputType([String])]

    [SuppressMessageAttribute('PSReviewUnusedParameter', '', Target = 'FilePath', Justification = 'This parameter is being used in a manner or scope that PSScriptAnalyzer cannot see.')]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
                $i = $_
                If ($_ -like 'a*') {
                    Set-Variable -PassThru -Scope 1 -Name "valString$([io.path]::GetRandomFileName())" -Value "${_}_validated" | ForEach-Object {[Boolean]$_}
                } Else {
                    Throw "I don't like $i"
                }
            })]
        [String[]]$InputString
    )

    Process { Get-Variable -Name 'valString*' | ForEach-Object {
        $_.Value
        Remove-Variable -Name $_.Name
    } }
}