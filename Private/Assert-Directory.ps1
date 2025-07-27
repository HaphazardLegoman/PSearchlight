Using namespace System.IO
Using namespace System.Management.Automation

function Assert-Directory {

    [CmdletBinding()] [OutputType([DirectoryInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path -IsValid -PathType Container -Path $_ })]
        [String[]]$Path
    )

    Begin {
        [Hashtable]$assertDirectory = @{
            ItemType    = 'Directory'
            ErrorAction = [ActionPreference]::Stop
        }
        [Hashtable]$atTarget = @{ Path = $null }
    }

    Process {
        Foreach ($p in $Path) {
            $atTarget.Path = $p
            Try { New-Item @assertDirectory @atTarget } Catch [IOException] {
                Foreach ($i in (Get-Item @atTarget)) { If ($i.PSIsContainer) { $i } Else { $PSCmdlet.WriteError( $_ ) } }
            }
        }
    }
}