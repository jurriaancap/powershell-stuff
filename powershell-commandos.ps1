*** modules

Get-Module –ListAvailable 


*** Voor OU ?? zet upn naar voorletter.achternaam@enzazaden.com

Get-ADUser -filter {(samaccountname -notlike "u41*")} -SearchBase "ou=??,ou=enzazaden,dc=intra,dc=local" -properties emailaddress | select name, userprincipalname, emailaddress | export-csv H:\exchange\??-users-old.csv -notypeinformation
Get-ADUser -filter {(samaccountname -notlike "u41*")} -SearchBase "ou=??,ou=enzazaden,dc=intra,dc=local" -properties emailaddress | foreach { Set-ADUser $_ -UserPrincipalName ("{0}.{1}@{2}" -f ($_.name).substring(0,1),($_.Surname).replace(" ",""),"enzazaden.com")}
Get-ADUser -filter {(samaccountname -notlike "u41*")} -SearchBase "ou=??,ou=enzazaden,dc=intra,dc=local" -properties emailaddress | select name, userprincipalname, emailaddress | export-csv H:\exchange\??-users-new.csv -notypeinformation


*** bewaar emailadres veld in AD in csv file

Get-ADUser -filter * -SearchBase "ou=user accounts,ou=dannstadt,ou=de,ou=enzazaden,dc=intra,dc=local" -Properties emailaddress | select samaccountname,emailaddress | export-csv h:\exchange\DE1-users.csv -notypeinformation


*** zet emailadres veld AD mbh csv file

Import-CSV h:\exchange\de1-users.csv | ForEach { set-aduser $_.samaccountname -emailaddress $_.emailaddress }


*** create mailboxes for existing AD users

Get-ADUser -filter {(samaccountname -notlike "u4*")} -SearchBase "ou=user accounts,ou=xxxxxxx,ou=??,ou=enzazaden,dc=intra,dc=local" | foreach { enable-mailbox -identity $_.userPrincipalName }


*** export pst's bulk -bad	

foreach ($i in (Get-Mailbox)) { New-MailboxExportRequest -Mailbox $i -FilePath "\\server\pst\$($i.Alias).pst" -ContentFilter {recieved -lt "01/01/2016"}}


*** import pst's bulk (PST bestanden dienen de User Logon name pre-windows 2000 inlognaam te hebben ( samaccountname )

Dir \\exnl0101\G$\exchange\PST_To_Import\*.pst | %{ New-MailboxImportRequest -Name BulkPSTImport -BatchName Recovered -Mailbox $_.BaseName -FilePath $_.FullName} 


***	importlog

Get-MailboxImportRequest | Get-MailboxImportRequestStatistics	
Get-MailboxImportRequest | Get-MailboxImportRequestStatistics -IncludeReport | fl >H:\exchange\Import-errorlog.txt


*** single pst import

New-MailboxImportRequest -Mailbox username -FilePath "\\exnl0102\r$\maildumps\vit\username.pst" -BadItemLimit 200 -AcceptLargeDataLoss


*** hide mailboxes by OU

get-mailbox -OrganizationalUnit "OU=au,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited |  Set-Mailbox -HiddenFromAddressListsEnabled $true


*** set mailbox features pop3 en imap4 op disable

get-mailbox -OrganizationalUnit "OU=??,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | set-casmailbox -imapenabled $false
get-mailbox -OrganizationalUnit "OU=??,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | set-casmailbox -popenabled $false


*** enable archive for accounts on MBXARCHIVE01 per ou

get-mailbox -OrganizationalUnit "OU=xxxxxxx,OU=??,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | Enable-Mailbox -Archive -ArchiveDatabase MBXARCHIVE02


*** mailbox size opvragen

get-mailbox -identity test2g2 | get-mailboxstatistics | select displayname, totalitemsize, database
get-mailbox -identity test2g2 -archive | get-mailboxstatistics -archive | select displayname, totalitemsize, database

Get-MailboxStatistics -Server exnl0102 | Sort-Object totalitemsize -descending | ft displayname,@{label="TotalItemSize(MB)";expression={$_.TotalItemSize.Value.ToMB()}},ItemCount >c:\zzzz\mailboxstats.txt

get-mailbox -OrganizationalUnit "OU=voorst,ou=nl,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | get-mailboxstatistics | ft displayname,@{label="TotalItemSize(MB)";expression={$_.TotalItemSize.Value.ToMB()}},ItemCount >H:\exchange\mailboxstats.txt

Get-Mailbox -OrganizationalUnit "OU=voorst,ou=nl,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | Get-MailboxStatistics | Sort-Object TotalItemSize -Descending | Select-Object DisplayName,@{Label="Size(Gb)"; Expression={$_.TotalItemSize.Value.ToGb()}} -First 10 | ft -auto

Get-Mailbox danielve | Get-MailboxStatistics | ft displayname,database,@{name="TotalItemSize (GB)"; expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}}

*** database whitespace 

Get-MailboxDatabase -Server exnl0102 -Status | sort-object name | select name,availablenewmailboxspace

*** mailbox verplaatsen van database

New-MoveRequest -Identity "Alan.Reid" -ArchiveOnly -ArchiveTargetDatabase "Archive Mailboxes"

Get-MailboxImportRequest -Status Completed
Get-MailboxImportRequest -Status Queued
Get-MailboxImportRequest -Status InProgress
Get-MailboxImportRequest -Status Failed 
Get-MailboxImportRequest -Status Completed | Remove-MailboxImportRequest


*** voeg extra adressen toe via csv file gebruik indeling AD voor userloginname smtp voor extra adres

Import-CSV h:\exchange\smtp2.csv | ForEach {Set-Mailbox $_.AD -EmailAddresses @{add=$_.smtp}}

*** AD restore account per ongeluk weggegooid

Get-ADObject -Filter {Name -like "frans*" -and isDeleted -eq $true} -IncludeDeletedObjects 
Get-ADObject -Filter {Name -like "jean*" -and isDeleted -eq $true} -IncludeDeletedObjects | Restore-ADObject

*** exchange automapping 

(Get-ADUser danielve -Properties *).msexchdelegatelistbl
(Get-ADUser danielve -Properties *).msexchdelegatelistLink

$FixAutoMapping = Get-MailboxPermission sharedmailbox |where {$_.AccessRights -eq "FullAccess" -and $_.IsInherited -eq $false}
$FixAutoMapping | Remove-MailboxPermission
$FixAutoMapping | ForEach {Add-MailboxPermission -Identity $_.Identity -User $_.User -AccessRights:FullAccess -AutoMapping $false} 

get-mailbox -OrganizationalUnit "OU=User Accounts,OU=voorst,OU=nl,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | Get-MailboxPermission -User carolienh | select identity,accessrights | ft -AutoSize

get-mailbox -OrganizationalUnit "OU=User Accounts,OU=voorst,OU=nl,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | Get-MailboxPermission -User carolienh | Add-MailboxPermission -Identity $_.identity -User carolienh -AccessRights:FullAccess -AutoMapping $false

$automap = get-mailbox -OrganizationalUnit "OU=User Accounts,OU=voorst,OU=nl,OU=EnzaZaden,DC=INTRA,DC=local" -resultsize unlimited | Get-MailboxPermission -User carolienh
$automap | remove-mailboxpermission
$automap | foreach {Add-MailboxPermission -identity carolienh -user $.indentity -AccessRights:FullAccess -AutoMapping $false}

*** database size opvragen exchange

Get-MailboxDatabase mbxarchive01 -status | foreach-object {add-member -inputobject $_ -membertype noteproperty -name mailboxdbsizeinGB -value ([math]::Round(([int64](get-wmiobject cim_datafile -computername $_.server -filter ('name=''' + $_.edbfilepath.pathname.replace("\","\\") + '''')).filesize / 1GB),2)) -passthru} |  Sort-Object mailboxdbsizeinGB -Descending | ft identity,mailboxdbsizeinGB,AvailableNewMailboxSpace -autosize

*** database mailbox whitespace

Get-MailboxDatabase -Server exnl0102 -Status | ft name,availablenewmailboxspace


*** DAG rebalance databases

F:\Exchange\Scripts\RedistributeActiveDatabases.ps1 -DagName exnldag01 -BalanceDbsByActivationPreference

*** Tel aantal gebruikers in ou

(Get-ADUser -Filter * -SearchBase "ou=user accounts,ou=moscow,ou=ru,ou=enzazaden,dc=intra,dc=local").count

*** remote powershell (op remote server moet enable-psremote zijn uitgevoerd)

Enter-PSSession -ComputerName DBNL0152 -Credential daniel_adm
add-pssnapin Microsoft.Exchange.Management.PowerShell.E2010

*** remote exchange powershell

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://<FQDN of Exchange 2010 server>/PowerShell/ -Authentication Kerberos
import-pssession $Session

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://exnl0106.intra.local/PowerShell/ -Authentication Kerberos
import-pssession $Session

Enter-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://exnl0106.intra.local/PowerShell/ -Authentication Kerberos

*** exchange 2010 activesync policy

get-CASMailbox | where{$_.activesyncmailboxpolicy -match “Enza Zaden Default”}

*** Public Folders rights

Add-PublicFolderClientPermission -Identity "\FR - Public" -AccessRights PublishingEditor -User ???

*** disconnected mailboxen

Get-MailboxStatistics -server exnl0102 | where {$_.DisconnectReason -eq "SoftDeleted"} | ft displayname,totalitemsize,lastloggedonuseraccount,disconnectdate


*** haal harddrive informatie op

Get-WmiObject -Query "select * from win32_logicaldisk where Drivetype = 3" -ComputerName exnl0102 | ft systemname,deviceid,volumename,@{name="Size(GB)";expression={"{0:N1}" -f($_.size/1gb)}},@{name="Freespace (GB)";Expression={"{0:N1}" -f($_.freespace/1gb)}}
Get-WmiObject -ComputerName exnl0102 -Class Win32_Volume -Filter "DriveType = 3" | sort-object name |  where-object {$_.Name -like "*:\"} | ft @{name="Drive";Expression={$_.name}},@{name="Freespace (GB)";Expression={"{0:N1}" -f($_.freespace/1gb)}},@{name="Disk Size(GB)";Expression={"{0:N1}"-f($_.capacity/1gb)}},label -AutoSize

Get-WmiObject -ComputerName exnl0102 -Class Win32_Volume -Filter "DriveType = 3" | where-object{$_.Name -like "*:\"} | sort-object name | ft systemname,name,@{name="Freespace (GB)";Expression={"{0:N1}" -f($_.freespace/1gb)}},@{name="Capacity (GB)";Expression={"{0:N1}" -f($_.capacity/1gb)}},label,blocksize -AutoSize

*** verwijder disconnected mailbox handmatig

Get-MailboxStatistics -Database arcmbx02 | where {$_.DisconnectReason -eq "SoftDeleted"} |  foreach {Remove-StoreMailbox -Database $_.database -Identity $_.mailboxguid -MailboxState SoftDeleted}

*** get owamailboxpolicy

(get-OwaMailboxPolicy -identity Default).AllowedFileTypes
Set-OwaMailboxPolicy -identity Default -AllowedFileTypes  @{add= '.xml'}

*** copy role and remove/add options

Get-ManagementRole mydistributiongroups | Get-ManagementRoleEntry

--make new role using existing role
New-ManagementRole -Name MyDistributionGroupsEnza -Parent MyDistributionGroups

--change options
Remove-ManagementRoleEntry MyDistributionGroupsEnza\New-DistributionGroup -Confirm:$false
Remove-ManagementRoleEntry MyDistributionGroupsEnza\Remove-DistributionGroup -Confirm:$false

--assign role to role policy
New-ManagementRoleAssignment -Role MyDistributionGroupsEnza -Policy “Default Role Assignment Policy”

--You are finished.  Now, owners of the groups can manage the users within the group, but they cannot create new groups, and delete existing group.

*** get accounts for reporting

Get-ADUser danielve -Properties * | fl givenname,surname,name,distinguishedname,passwordexpired,passwordlastset,lastlogondate,lastbadpasswordattempt,created,accountexpirationdate,description,objectclass,lockedout,enabledm

*** free/busy details shared calendar

Get-MailboxFolderPermission bmr-3:\calendar
set-MailboxFolderPermission bmr-3:\calendar -User Default -AccessRights LimitedDetails

*** password fine grained policies

Get-ADFineGrainedPasswordPolicy -Filter * | ft name

*** get-event security log

Get-EventLog -computername dcnl0101 -logname security -instanceid 4740 -newest 5 | select @{n='Computer Source';e={$_.ReplacementStrings[1]}},@{n='Account Name';e={$_.ReplacementStrings[0]}},timegenerated

*** uninstall sccm client

#Start process to uninstall SCCM Client.  Contains a loop to wait for successful uninstall before moving on.
Write-Host Uninstalling SCCM Client, please wait...
Start-Process -FilePath 'C:\Windows\ccmsetup\ccmsetup.exe' -ArgumentList '/uninstall'
    do {(Start-Sleep -Milliseconds 600)}
until (select-string -Path C:\Windows\ccmsetup\Logs\ccmsetup.log -Pattern "Uninstall succeeded") 
#End SCCM Uninstall.
Write-Host SCCM Client uninstalled.

*** send email with powershell 

Send-MailMessage -To d.vanelk@enzazaden.nl -Subject "test" -Body "test" -SmtpServer mail.enzazaden.com -From asnl0132@intra.local

*** schema version check

# Exchange Schema Version
$sc = (Get-ADRootDSE).SchemaNamingContext
$ob = "CN=ms-Exch-Schema-Version-Pt," + $sc
(Get-ADObject $ob -pr rangeUpper).rangeUpper

(Get-ADObject ("CN=ms-Exch-Schema-Version-Pt,"+(Get-ADRootDSE).SchemaNamingContext) -pr rangeUpper).rangeUpper

# Exchange Object Version (forest)
$cc = (Get-ADRootDSE).ConfigurationNamingContext
$fl = "(objectClass=msExchOrganizationContainer)"
(Get-ADObject -LDAPFilter $fl -SearchBase $cc -pr objectVersion).objectVersion

(Get-ADObject -LDAPFilter "(objectClass=msExchOrganizationContainer)" -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -pr objectVersion).objectVersion

# Exchange Object Version (domain) - assumes single domain forest
$dc = (Get-ADRootDSE).DefaultNamingContext
$ob = "CN=Microsoft Exchange System Objects," + $dc
(Get-ADObject $ob -pr objectVersion).objectVersion

(Get-ADObject ("CN=Microsoft Exchange System Objects,"+(Get-ADRootDSE).defaultnamingcontext) -pr objectversion).objectversion

*** get exchange version numbers/build

$ExchangeServers = Get-ExchangeServer  | Sort-Object Name 
ForEach  ($Server in $ExchangeServers) {Invoke-Command -ComputerName $Server.Name -ScriptBlock {Get-Command  Exsetup.exe | ForEach-Object {$_.FileversionInfo}}}

find buildnumbers on http://social.technet.microsoft.com/wiki/contents/articles/240.exchange-server-and-update-rollups-build-numbers.aspx
Get-ExchangeServer | Sort-Object Name | ForEach{ Invoke-Command -ComputerName $_.Name -ScriptBlock { Get-Command ExSetup.exe | ForEach{$_.FileVersionInfo } } } | Format-Table -Auto 

*** exchange roomlist

Get-DistributionGroup | Where {$_.RecipientTypeDetails -eq "RoomList"} | Format-Table DisplayName,Identity,PrimarySmtpAddress

*** SQL

import-module sqlps

$SQLsrvDBs = New-Object 'Microsoft.SqlServer.Management.SMO.Server' DBNL0103
$sqlsrvdbs.databases | ft name,status,recoverymodel,@{name="SQLversion";Expression={($_.CompatibilityLevel).ToString().Replace("Version", "")}},owner -AutoSize

*** VMWare powercli

Get-PSSnapin VMware* -Registered
add-pssnapin vmw*
get-command -Module vmware.vimautomation.core

connect-viserver mtnl0109
get-command -Module vmware.vimautomation.core

*** MS online (office 365)

import-module MSonline
connect-msonlineservice -credentials (get-credentials)

*** get msoluser filtered

Get-MsolUser -all |where {$_.UserPrincipalName.ToLower().EndsWith("@enzazaden.com")}

*** get license options for O365

Get-MsolAccountSku | Where-Object {$_.accountskuid -eq "EZNLB:ENTERPRISEPACK"} | ForEach-Object {$_.ServiceStatus}

*** set skype license for user office 365 

$LO = New-MsolLicenseOptions -AccountSkuId "EZNLB:ENTERPRISEPACK" -DisabledPlans "Deskless", "FLOW_O365_P2", "POWERAPPS_O365_P2", "TEAMS1", "PROJECTWORKMANAGEMENT", "SWAY", "YAMMER_ENTERPRISE", "RMS_S_ENTERPRISE", "OFFICESUBSCRIPTION", "SHAREPOINTWAC", "SHAREPOINTENTERPRISE", "EXCHANGE_S_ENTERPRISE"

Set-MsolUserLicense -UserPrincipalName <account> -add "EZNLB:ENTERPRISEPACK"
Set-MsolUserLicense -UserPrincipalName <account> -LicenseOptions $LO

$AllLicensed = Get-MsolUser -All | where {$_.isLicensed -eq $true}
$AllLicensed | foreach {Set-MsolUserLicense -LicenseOptions $LO}

*** trust relation stuk na vmware tools

Reset-ComputerMachinePassword -Server dcnl0101 -Credential (Get-Credential)

*** office 365 ADFS convert domain managed to federated

Set-MsolADFSContext -Computer mtnl0128
Convert-MsolDomainToFederated -DomainName "enzazaden.com.ua" -SupportMultipleDomain

*** office 365 powershell remote session

$cred = Get-Credential
$ses = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication basic -AllowRedirection
Import-PSSession $ses

*** convert ad objectguid to immutableid
$upn = "d.vanelk@enzazaden.nl"
$id=(Get-ADUser -Filter {UserPrincipalName -like $upn } -Properties ObjectGUID | select ObjectGUID | foreach {[system.convert]::ToBase64String(([GUID]($_.ObjectGUID)).tobytearray())})
$id

Get-ADUser danielve -Properties ObjectGuid | ft userprincipalname,@{name="imute";expression={[system.convert]::ToBase64String(([GUID]($_.ObjectGUID)).tobytearray())}}

*** purge quaraintain activesync devices

Get-ActiveSyncDevice | Where {$_.DeviceAccessState -eq "Quarantined" -and $_.FirstSyncTime -lt (Get-Date).AddMonths(-1)} | Remove-ActiveSyncDevice -Confirm:$false

*** convert dist group to roomlist

Set-DistributionGroup -Identity "Bldg34 Conf Rooms" -RoomList

*** cert signing

certreq -submit -attrib "CertificateTemplate:ENZA-WebServersha2" ‘drive\path\filename’

*** exo move status

Get-MoveRequest | where{$_.MoveStatus -ne "Completed"} | Get-MoverequestStatistics | ft alias, statusdetail, percentcomplete, bytestrans* -auto

*** disconnected mailboxes

Get-MailboxStatistics -server <servername> | where { $_.DisconnectDate -ne $null } | select DisplayName,MailboxGuid,Database,DisconnectDate

*** Force sync azure ad 

Import-Module ADSync

-For a Delta Sync (most common, and used for most situations):
Start-ADSyncSyncCycle -PolicyType Delta

-For a Full Sync (only necessary in some situations):
Start-ADSyncSyncCycle -PolicyType Initial

*** create roomlist synced with hybrid exchange

New-ADGroup -Name "Rooms-NL-Enkhuizen" -path "ou=azure groups,ou=Groups,ou=ww,ou=enzazaden,dc=intra,dc=local" -OtherAttributes @{msExchRecipientTypeDetails='268435456';mail='Rooms-NL-Enkhuizen@enzazaden.com'} -GroupCategory Security -GroupScope Global

*** connect powershell exchange online

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection