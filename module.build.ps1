Using namespace System.Collections.Generic
Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.IO
Using namespace System.Management.Automation
Using namespace System.Text

Param(
    [Parameter()][String]$ModuleName,
    [Parameter()][String]$ExcludeFilter
)

Set-StrictMode -Version Latest

# Self-contained build script - can be invoked directly or via Invoke-Build
If ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    & "$PSScriptRoot\_bootstrap.ps1"
    Invoke-Build -File $MyInvocation.MyCommand.Path @PSBoundParameters -Result Result
    If ($Result.Error) {
        $Error[-1].ScriptStackTrace | Out-String
        Exit 1
    }
    Exit 0
}

$ErrorActionPreference = [ActionPreference]::Stop

#region functions
function Get-NestedModuleManifestFile {

    [CmdletBinding()] [OutputType([FileInfo])] Param()

    $rootPath = Switch -Wildcard ($MyInvocation.ScriptName) {
        '*Invoke-Build.ps1' { $BuildRoot; Break }
        '*.ps1' { $PSScriptRoot; Break }
        Default { $PWD }
    }
    [Hashtable]$nestedModulePSDataFile = @{
        File        = $true
        Filter      = '*.psd1'
        Recurse     = $true
        Depth       = 1
        Path        = "$rootPath\NestedModules"
        ErrorAction = [ActionPreference]::Ignore
    }
    [Hashtable]$notModuleBuilderPSD1 = @{
        Property = 'BaseName'
        NE       = $true
        Value    = 'build'
    }
    Get-ChildItem @nestedModulePSDataFile | Where-Object @notModuleBuilderPSD1
}

function Get-ManifestNestedModuleList {

    [CmdletBinding()] [OutputType([String])]

    [SuppressMessageAttribute('PSReviewUnusedParameter', '', Target = 'FilePath', Justification = 'This parameter is being used in a manner or scope that PSScriptAnalyzer cannot see.')]

    Param(
        [Parameter(Mandatory)]
        [ValidateScript({
                Try {
                    $givenPath = $_
                    $resolvedPath = Resolve-Path -Path $givenPath -ErrorAction Stop
                    If (-not (Test-Path -PathType Leaf -Path $resolvedPath)) { Throw [ValidationMetadataException]::new("`"$givenPath`" is not a file.") }
                    ElseIf ([Path]::GetExtension($resolvedPath) -ne '.psd1') { Throw [ValidationMetadataException]::new("`"$givenPath`" is not a .psd1 file.") }
                    Else {$true}
                } Catch [ItemNotFoundException] {
                    Throw [ItemNotFoundException]::new("The file `"$givenPath`" does not exist.", $_.Exception)
                }
            })]
        [String]$FilePath,
        [Parameter()]
        [Switch]$IncludePrimaryModule
    )

    Try {
        $(Import-PowerShellDataFile -Path $FilePath).NestedModules.Where({
                If ($IncludePrimaryModule) { $_ } Else {
                    [Path]::GetFileNameWithoutExtension($_) -ne [Path]::GetFileNameWithoutExtension($FilePath)
                }
            })
    } Catch [InvalidOperationException] {
        Throw [InvalidOperationException]::new("The file `"$FilePath`" could not be parsed.", $_.Exception)
    } Catch [PropertyNotFoundException] {
        Write-Information -MessageData 'No nested modules are listed in the module manifest.'
    }
}

function Get-ModuleDevelopmentPublicFunctionName {

    [CmdletBinding()] [OutputType([String])]

    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({
                Try {
                    $givenPath = $_
                    $resolvedPath = Resolve-Path -Path $givenPath -ErrorAction Stop
                    If (-not (Test-Path -PathType Container -Path $resolvedPath)) {
                        Throw [ValidationMetadataException]::new("`"$givenPath`" is not a directory.")
                    } ElseIf (-not (Test-Path -PathType Container -Path "$resolvedPath\Public")) {
                        Throw [ValidationMetadataException]::new("`"$_`" does not contain a subdirectory called `"Public`".")
                    } Else {
                        $true
                    }
                } Catch [ItemNotFoundException] {
                    Throw [ItemNotFoundException]::new("Cannot find path `"$givenPath`" because it does not exist.", $_.Exception)
                }
            })]
        [String[]]$ModulePath,
        [Parameter()]
        [String]$ExcludeFilter
    )

    Begin {
        [Hashtable]$publicFunctionFile = @{
            File   = $true
            Filter = '*.ps1'
        }

        [Hashtable]$isNotExcluded = If ($ExcludeFilter) {
            @{
                Property = 'BaseName'
                NotMatch = $true
                Value    = $ExcludeFilter
            }
        } Else {
            @{ FilterScript = { $_ } }
        }
    }

    Process {
        Foreach ($m in $ModulePath) {
            Get-ChildItem @publicFunctionFile -Path "$m\Public" | Where-Object @isNotExcluded | Select-Object -ExpandProperty BaseName
        }
    }
}
#endregion functions

Enter-Build {

    # If (-not $PSBoundParameters.ContainsKey('ModuleName')) {
    #     Try {
    #         $ModuleName = Get-Item -Path $BuildRoot\*.ps1 | Where-Object -Property BaseName -NE -Value 'build' | Select-Object -ExpandProperty BaseName
    #     } Catch [ItemNotFoundException] {
    #         Try {
    #             $ModuleName = Import-PowerShellDataFile -Path $BuildRoot\build.psd1 | Select-Object -ExpandProperty ModuleManifest | ForEach-Object -Process {[IO.Path]::GetFileNameWithoutExtension($_)}
    #             New-ModuleManifest -Path "$BuildRoot\$ModuleName.psd1" -NestedModules $
    #         } Catch [ItemNotFoundException] {
    #             #$ModuleName = Read-Host -Prompt "Please provide a name for this module:"
    #             #If (-not $ModuleName) { Exit } Else {
    #             Exit
    #             #}
    #         }
    #     }
    # }

    [Hashtable]$inParentScope = @{Scope = 1 }
    Set-Variable @inParentScope -Name primaryManifestFile -Value $(Get-ChildItem -File -Filter '*.psd1' -Depth 0 -Path $PSScriptRoot | Where-Object -Property BaseName -NE -Value build)
    Set-Variable @inParentScope -Name everyManifest -Value $primaryManifestFile
    Set-Variable @inParentScope -Name requiredOutputDirectoryList -Value @('Build', 'Docs', 'en-US', 'Tests')
    Set-Variable @inParentScope -Name filter -Value $(Foreach ($h in $([Hashtable]@{})) { If ($ExcludeFilter) { $h.Add('ExcludeFilter', $ExcludeFilter)}; $h })
    Set-Variable @inParentScope -Name nestedModuleManifest -Value @()
    Set-Variable @inParentScope -Name copyPath -Value $(Split-Path -Parent -Path @())

    If (Join-Path -Path $BuildRoot -ChildPath 'NestedModules' -OutVariable nestedModuleParentDirectory | Test-Path) {

        If (Get-ChildItem -Path $nestedModuleParentDirectory) {
            Set-Variable @inParentScope -Name nestedModuleManifest -Value $(Get-NestedModuleManifestFile)
            Set-Variable @inParentScope -Name everyManifest -Value $(Foreach ($m in ($nestedModuleManifest,$primaryManifestFile)) {$m})
            Set-Variable @inParentScope -Name copyPath -Value $(Split-Path -Parent -Path $($nestedModuleManifest -replace 'NestedModules','Build' <#| Convert-ModuleFilePath -ToPath BuildOutput#>)) #$([List[DirectoryInfo]]::new())
        }
    }

    use "$env:LocalAppData\Microsoft\WinGet\Packages\GitTools.GitVersion_Microsoft.Winget.Source_8wekyb3d8bbwe" gitversion
}

#region tasks
task AssertGitVersionAvailable {
    Assert (Test-Path -Path "$env:LocalAppData\Microsoft\WinGet\Packages\GitTools.GitVersion_Microsoft.Winget.Source_8wekyb3d8bbwe\gitversion.exe")
}

task AssertNestedModuleAgreement -If ($null -ne $nestedModuleManifest) {

    [String[]]$manifestNestedModuleName = Get-ManifestNestedModuleList -FilePath $primaryManifestFile | ForEach-Object -Process { (Split-Path -Leaf -Path $_) -replace '\.psm1' }
    [String[]]$nestedModuleBuildDirectoryName = Get-NestedModuleManifestFile | Select-Object -ExpandProperty BaseName
    Assert ($null -eq $(Compare-Object -ReferenceObject $manifestNestedModuleName -DifferenceObject $nestedModuleBuildDirectoryName))
}

task MakeRequiredDirectories {
    Foreach ($d in $($requiredOutputDirectoryList.Where({ -not (Test-Path -PathType Container -Path "$BuildRoot\$_") }))) {
        exec { New-Item -ItemType Directory -Path "$BuildRoot\$d" }
    }
}

task TestFilter {
    $filter | ConvertTO-Json | Out-File .\filter.txt
}

task BuildNestedModules @{
    If      = ($null -ne $nestedModuleManifest)
    Inputs  = { Get-NestedModuleManifestFile }
    Outputs = { Process { [Path]::ChangeExtension($($_ -replace 'NestedModules','Build'), '.psm1') <#Convert-ModuleFilePath -Path $_ -ToPath BuildOutput -ToType ScriptModule#> } }
    Jobs    = {
        Process {
            [String]$directory = Split-Path -Parent -Path $_
            [Hashtable]$nestedModule = @{
                SourcePath      = $directory
                OutputDirectory = Split-Path -Parent -Path $($_ -replace 'NestedModules','Build'<#Convert-ModuleFilePath -Path $_ -ToPath BuildOutput#>)
                Suffix          = "Export-ModuleMember -Function @($([Environment]::NewLine)    '$((Get-ModuleDevelopmentPublicFunctionName -ExcludeFilter $ExcludeFilter -ModulePath $directory | Sort-Object) -join "',$([Environment]::NewLine)    '")'$([Environment]::NewLine))"
            }
            Build-Module @nestedModule
        }
    }
}

task TrimAutoRegionTags {
    #TODO implement this later. It's mostly cosmetic so I don't need to figure it out now.
    #TODO ditto with commented-out Using statements.
}

task RemoveBuiltNestedModuleManifests -If ($null -ne $nestedModuleManifest) { Remove ((Get-NestedModuleManifestFile) -replace 'NestedModules','Build') }

task TestFunctionListExclusion {
    $(Get-ModuleDevelopmentPublicFunctionName -ExcludeFilter $ExcludeFilter -ModulePath $primaryManifestFile.Directory | Sort-Object) | Out-File -FilePath .\exclusion.txt
}

task BuildPrimaryModule -Jobs 'AssertNestedModuleAgreement', 'MakeRequiredDirectories', 'BuildNestedModules', {

    $functionList = $(Get-ModuleDevelopmentPublicFunctionName -ExcludeFilter $ExcludeFilter -ModulePath $everyManifest.Directory | Sort-Object)
    $exportStatement = "Export-ModuleMember -Function @($([Environment]::NewLine)    '$($functionList -join "',$([Environment]::NewLine)    '")'$([Environment]::NewLine))"

    [Hashtable]$primaryModule = @{
        SourcePath = $BuildRoot
        CopyPaths  = $copyPath
        Suffix     = $exportStatement
        SemVer     = exec { gitversion "$BuildRoot" -output json /showvariable semver }
    }
    Build-Module @primaryModule

    [Hashtable]$overwriteFunctionExportList = @{
        Path              = Get-ChildItem -File -Filter $primaryManifestFile.Name -Recurse -Path "$BuildRoot\Build\$($primaryManifestFile.BaseName)"
        FunctionsToExport = $functionList
    }
    Update-ModuleManifest @overwriteFunctionExportList
    # TODO: The results of Update-ModuleManifest are incredibly ugly. Maybe write my own regex-based function to do this properly when I want to more fully automate (or publish)
}

task MakeTestFilesForNewFunctions @{
    Partial = $true
    Inputs  = { Get-ChildItem -File -Filter '*.ps1' -Path "$BuildRoot\NestedModules" }
    Outputs = {}
    Jobs    = {}
    #TODO make this. Partial incremental since there is a 1:1 relationship between the files.
}

task CleanNestedModules -If ($null -ne $nestedModuleManifest) { Remove $(Split-Path -Parent -Path ((Get-NestedModuleManifestFile) -replace 'NestedModules','Build' <#| Convert-ModuleFilePath -ToPath BuildOutput#>)) }

task CleanAll -If (Get-Item -Path "$BuildRoot\Build\*" -ErrorAction Ignore) -Jobs { Remove "$BuildRoot\Build\*" }

task UpdateHelp {

}

task InitializeHelp -Jobs {
    Partial = $true
    Inputs = {}
    Outputs = {}
    Jobs = {

        $forModule = @{
            AlphabeticParamsOrder = $true
            WithModulePage        = $true
            ExcludeDontShow       = $true
            Encoding              = [Encoding]::UTF8
            OutputFolder          = $OutputFolder
            Module                = Foreach ($m in $script:primaryManifestFile) {
                Get-Module -Name $m.BaseName | Remove-Module -Force
                Import-Module -Force -PassThru -Name $([Path]::Combine($m.Directory, 'Build', $m.Name)) | Select-Object -ExpandProperty Name
            }
        }
        New-MarkdownHelp @forModule
    }
    #TODO make this if needed. It's possible PlatyPS does this already.
}

task . 'AssertNestedModuleAgreement', 'CleanAll', 'BuildNestedModules', 'RemoveBuiltNestedModuleManifests', 'BuildPrimaryModule'
#endregion tasks