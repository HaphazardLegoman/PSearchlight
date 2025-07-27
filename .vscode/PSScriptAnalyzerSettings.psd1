@{
    ExcludeRules = @('PSProvideCommentHelp') # TODO remove this later in development
    Rules        = @{
        PSUseCompatibleCmdlets  = @{
            Compatibility = @('desktop-5.1.14393.206-windows')
            IgnoreCommands = @(
                'Update-ModuleManifest' # False positive
            )
        }
        PSUseCompatibleCommands = @{
            Enable         = $true
            IgnoreCommands = @(
                'Context',              # Pester command
                'Install-Module',       # False positive
                'Should'                # Pester command
            )
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework' # Windows PowerShell 5.1, Windows 10 Pro
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework' # Windows PowerShell 5.1, Server 2019
            )
        }
        PSUseCompatibleSyntax   = @{
            Enable         = $true
            TargetVersions = @(
                '5.1'
            )
        }
        PSUseCompatibleTypes    = @{
            Enable         = $true
            TargetProfiles = @(
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework' # Windows PowerShell 5.1, Windows 10 Pro
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework' # Windows PowerShell 5.1, Server 2019
            )
        }
    }
}