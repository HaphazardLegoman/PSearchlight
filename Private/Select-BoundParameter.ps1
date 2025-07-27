Using namespace System.Collections.Generic
Using namespace System.Management.Automation

function Select-BoundParameter {

    [CmdletBinding(DefaultParameterSetName = 'ReferenceCommand')] [OutputType([Hashtable])]

    Param(
        [Parameter(Mandatory, ParameterSetName = 'ReferenceCommand')]
        [ValidateScript({
                Try {
                    New-Variable -Scope 1 -Name targetCommand -Value $([String]::Empty)
                    Get-Command -Name $_ -ErrorAction Stop | Tee-Object -Variable script:targetCommand | ForEach-Object { [Boolean]$_ }
                } Catch [Management.Automation.CommandNotFoundException] {
                    Throw $_
                }
            })]
        [String]$ReferenceCommand,
        [Parameter(ParameterSetName = 'ReferenceCommand')]
        [ValidateScript({
                If ([Cmdlet]::CommonParameters -notcontains $_) { $true } Else {
                    Throw [ArgumentException]::new("`"$_`" is a PowerShell cmdlet common parameter and will be excluded by default.")
                } #TODO: Maybe this should be a warning within the logic instead of a terminating exception?
            })]
        [String[]]$ExcludeParameter,
        [Parameter(ParameterSetName = 'ReferenceCommand')]
        [ValidateScript({
                If ([Cmdlet]::CommonParameters -contains $_) { $true } Else {
                    Throw [ArgumentException]::new("`"$_`" is not a PowerShell cmdlet common parameter.")
                }
            })]
        [String[]]$IncludeCommonParameter,
        [Parameter(Mandatory, ParameterSetName = 'SpecifyName')]
        [String[]]$ParameterName,
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]$PSBoundParameterDictionary # I wanted to set this to $PSBoundParameters by default, but scoping will prevent that
        <#
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSTypeName('System.PSBoundParametersDictionary')] # would this work with GroupInfo too??
        [PSObject]$PSBoundParameterDictionary
        #>
        <#
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Collections.Generic.Dictionary[[String],[ParameterMetadata]]]
        $ParameterMetadataDictionary #works for $((Get-Command 'Get-Item').Parameters)
    # OR, alternatively, if I can't have both supported from the pipeline as-is:
        [Parameter(Mandatory, ValueFromPipeline)]
        [ParameterMetadata[]]
        $ParameterMetadata
        #>
    )

    Begin {
        [List[String]]$skipParameter = [List[String]]::New([Cmdlet]::CommonParameters)
        [Hashtable]$selectedParameter = @{}
    }

    Process {

        [Hashtable]$matchingParameter = @{
            ReferenceObject  = $null
            DifferenceObject = Get-DictionaryKeyName -InputObject $PSBoundParameterDictionary
            IncludeEqual     = $true
            ExcludeDifferent = $true
        }
        $matchingParameter.ReferenceObject = If ($PSCmdlet.ParameterSetName -eq 'SpecifyName') { $ParameterName } Else {
            Get-DictionaryKeyName -InputObject $script:targetCommand.Parameters
        }

        If ($overlappingParameter = Compare-Object @matchingParameter | Select-Object -ExpandProperty InputObject) {

            $filteredParameterName = If ($PSCmdlet.ParameterSetName -eq 'SpecifyName') { $overlappingParameter } Else {
                If ($PSBoundParameters.ContainsKey('IncludeCommonParameter')) {
                    Foreach ($c in $IncludeCommonParameter) { Out-Null -InputObject $($skipParameter.Remove("$c")) }
                }
                If ($PSBoundParameters.ContainsKey('ExcludeParameter')) { Foreach ($p in $ExcludeParameter) { $skipParameter.Add($p) } }
                $overlappingParameter | Where-Object -FilterScript { $skipParameter -notcontains $_ }
            }
            Foreach ($p in $filteredParameterName) { $selectedParameter.Add($p, $PSBoundParameterDictionary.($p)) }

            Return $selectedParameter
        }
    }
}