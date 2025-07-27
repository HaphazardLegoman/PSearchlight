#Requires -PSEdition Core
#Requires -Module Pester

Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.IO
Using namespace System.Management.Automation

Set-StrictMode -Version Latest

# When setting variables for use in later scriptblocks, use Set-Variable to avoid PSScriptAnalyzer false positives for the rule PSUseDeclaredVarsMoreThanAssignments

BeforeAll {
    . $($PSCommandPath -replace 'Tests[\.\\]') # Removes the Tests directory and the .Tests name fragment from the path to find the path of the file to be tested
}

Describe Open-Bitmap {}