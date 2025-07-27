Using namespace System.Collections.Generic
Using namespace System.Diagnostics.CodeAnalysis
Using namespace System.Drawing
Using namespace System.Management.Automation
Using namespace System.Text

function Select-Bitmap {

    [CmdletBinding()] [OutputType([String])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)][Bitmap[]]$InputObject,
        [Parameter()][ImageOrientation[]]$Orientation = @('Landscape', 'Portrait', 'Square'),
        [Parameter()][Int32]$MinByteSize,
        [Parameter()][Int32]$MaxByteSize
    )

    Begin {
        [List[String]]$matchingImage = @() #= [StringBuilder]::new()
        Switch ($PSBoundParameters.Keys) {
            'Orientation' { $matchingImage.Add('($Orientation -contains (Measure-BitmapOrientation -InputObject $_))')}
            'MinByteSize' { $matchingImage.Add('') }
            'MaxByteSize' { $matchingImage.Add('') }
        }

        $matchingImage = [StringBuilder]::new('($Orientation -contains (Measure-BitmapOrientation -InputObject $_))')
        If ($PSBoundParameters.ContainsKey('MinByteSize')) {
            $matchingImage.Append(' -and ()')
        }
        If ($PSBoundParameters.ContainsKey('MaxByteSize')) {
            $matchingImage.Append(' -and ()')
        }

        [ScriptBlock]::new(" -and ()")
    }

    Process {
        $InputObject | Where-Object
    }
}