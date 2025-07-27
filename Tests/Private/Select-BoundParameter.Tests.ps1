#Requires -PSEdition Core
#Requires -Module Pester

Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.IO
Using namespace System.Management.Automation

Set-StrictMode -Version Latest

# When setting variables for use in later scriptblocks, use Set-Variable to avoid PSScriptAnalyzer false positives for the rule PSUseDeclaredVarsMoreThanAssignments

BeforeAll {

    . "$($PSCommandPath -replace 'Tests[\.\\]')" #removes the Tests directory and the .Tests name fragment from the path to find the path of the file to be tested

    # Set-Variable -Name 'd' -Value @{ ItemType = 'Directory' }
    # Set-Variable -Name 'f' -Value @{ ItemType = 'File' }
    # Set-Variable -Name 'ref' -Value 'TestDrive:\Ref'
    # Set-Variable -Name 'diff' -Value 'TestDrive:\Diff'
    # Set-Variable -Name 'compareTestDrive' -Value @{
    #     ReferencePath  = $ref
    #     DifferencePath = $diff
    # }
}

Describe Select-BoundParameter {

    BeforeAll {
        function Get-DictionaryKeyName {} # dummy function so we don't have to load the real one just to mock it.
        function Invoke-Imagination {
            [CmdletBinding()] Param([String]$Path,[String]$Filter,[Switch]$Force)
            Return $PSBoundParameters
        } # easy way for us to get a PSBoundParametersDictionary object
    }

    Context 'when ReferenceCommand is specified with no other parameters' {

        BeforeAll {
            Set-Variable -Name examplePath -Value 'C:\temp'
            Set-Variable -Name mockPSBoundParameters -Value $(Invoke-Imagination -Path $examplePath)
        }

        BeforeEach {

            Mock -CommandName 'Get-DictionaryKeyName' -ParameterFilter { $InputObject -ne $mockPSBoundParameters } -MockWith {
                $(Get-command -Name Get-Item | Select-Object -ExpandProperty Parameters).Keys
            }
            Mock -CommandName 'Get-DictionaryKeyName' -ParameterFilter { $InputObject -eq $mockPSBoundParameters } -MockWith { 'Path' }
            Set-Variable -Name output -Value $($mockPSBoundParameters | Select-BoundParameter -ReferenceCommand 'Get-Item')
        }

        It 'should return a hashtable' {
            $output | Should -BeOfType [Hashtable]
        }

        It 'should return parameters that overlap with the ReferenceCommand' {
            $output | Should -HaveCount 1 -Because '$mockPSBoundParameters contains only $Path'
            $output.Keys | Should -Contain 'Path'
            $output.Path | Should -BeExactly $examplePath
        }

        AfterEach {
            Should -Invoke 'Get-DictionaryKeyName' -Exactly 2 -Because 'only the SpecifyName parameter set will call Get-DictionaryKeyName fewer times.'
        }
    }

    Context 'when ExcludeParameter is specified' {}

    Context 'when IncludeCommonParameter is specified' {}

    Context 'when ParameterName is specified to use the SpecifyName parameter set' {

        AfterEach {
            Should -Invoke 'Get-DictionaryKeyName' -Exactly 1 -Because 'the SpecifyName parameter set skips over one of the two uses of Get-DictionaryKeyName.'
        }
    }

    #region ParameterValidation
    Context 'when ReferenceCommand is given an invalid argument' {
        # It 'should throw a terminating error' {}
    }

    Context 'when ExcludeParameter is given an invalid argument' {
        # It 'should throw a terminating error' {}
    }

    Context 'when IncludeCommonParameter is given an invalid argument' {
        # It 'should throw a terminating error' {}
    }

    Context 'when $PSBoundParameterDictionary is given an invalid argument' {

        # It 'should throw a terminating error' {}
    }
    #endregion ParameterValidation
}