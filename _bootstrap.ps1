Using namespace System.Collections.Generic
Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.Management.Automation

[SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Target = 'Install-Module', Justification = 'Go home, PSScriptAnalyzer. You are drunk.')]
Param()

#region declarations
[List[String]]$requiredModuleList = @(
    'InvokeBuild'
    'ModuleBuilder'
    'Pester',
    'PlatyPS'
)

[List[PSCustomObject]]$requiredToolInfo = @(
    [PSCustomObject]@{
        Name = 'GitTools.GitVersion'
        Path = "$env:LocalAppData\Microsoft\WinGet\Plackages\GitTools.GitVersion_Microsoft.Winget.Source_8wekyb3d8bbwe\gitversion.exe"
    }
)
#endregion declarations

#region functions
function Install-WinGetApp {

    Param([Parameter(Mandatory, ValueFromPipeline)][String[]]$Name)

    Process { Foreach ($n in $Name) { & winget install --exact --id $n --scope user --source winget --accept-package-agreements } }
}
#endregion functions

#region logic
Foreach ($m in $requiredModuleList) {
    If (-not (Get-Module -ListAvailable -Name $m)) {
        Install-Module -Force -Repository PSGallery -Name $m
    }
}

Foreach ($t in $requiredToolInfo) {
    If (-not (Test-Path -Path $t.Path)) {Install-WinGetApp -Name $t.Name}
}
#endregion logic