# scratchpad

<#Get-CimInstance -class Win32_LogicalDisk `
-filter "drivetype=4" |
Select -Property DeviceID,Size,freespace |
sort -Property freespace -Descending
#>
<# [CmdletBinding()]
param()
$data = import-csv c:\tmp\data.csv
Write-Debug "Imported CSV data"
$totalqty = 0
$totalsold = 0
$totalbought = 0
    foreach ($line in $data) {
        if ($line.transaction -eq 'buy') {
        # buy transaction (we sold)
        Write-Debug "ENDED BUY transaction (we sold)"
        $totalqty -= $line.qty
        $totalsold += $line.total
        } else {
        # sell transaction (we bought)
        $totalqty += $line.qty
        $totalbought += $line.total
        Write-Debug "ENDED SELL transaction (we bought)"
        }
    }

Write-Debug "OUTPUT: $totalqty,$totalbought,$totalsold,$($totalbought-$totalsold)"
"totalqty,totalbought,totalsold,totalamt" | out-file c:\tmp\summary.csv
"$totalqty,$totalbought,$totalsold,$($totalbought-$totalsold)" |out-file c:\tmp\summary.csv -append
 #>