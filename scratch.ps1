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

 #read event log for when a group is created 
$event  = get-eventlog security -ComputerName dcnl0101.intra.local | Where-object {($_.EventID -eq  4727) -or ($_.EventID -eq 4754) -or ($_.EventID -eq 4731)}

$event | select MachineName,EventID,TimeGenerated,Message | 
Export-Csv -path "E:\EventLogs\AccountAudit.csv" -Append -Encoding ASCII 


#credentials in file storen
$Credential = Get-Credential
#To store the credentials into a .cred file:
$Credential | Export-CliXml -Path "${env:\userprofile}\example.Cred"
#And to load the credentials from the file and back into a variable:
$Credential = Import-CliXml -Path "${env:\userprofile}\example.Cred"
# example : Invoke-Command -Computername 'Server01' -Credential $Credential {whoami}

