#load correct snapin 
Add-PSSnapin VMware.VimAutomation.Core
#connect to vcenter

$Credential = Get-Credential
Connect-VIServer vcenter.intra.local -Credential $Credential

Get-vm 


