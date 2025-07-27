Using namespace System.Drawing

function Measure-BitmapOrientation {

    [CmdletBinding()] [OutputType([String])]

    Param([Parameter(Mandatory, ValueFromPipeline)][Bitmap[]]$InputObject)

    Process {
        Foreach ($i in $InputObject) {
            Switch ($i.Width) {
                { $_ -gt $i.Height } { 'Landscape' }
                { $_ -lt $i.Height } { 'Portrait' }
                { $_ -eq $i.Height } { 'Square' }
            }
            $i.Dispose()
        }
    }
}