If ( ! (Get-module activedirectory )) { 

    Import-Module activedirectory
    
    }
    function Pause
    
    {
    
       Read-Host 'Press Enter to continue…' | Out-Null
    
    }
    
    $ErrorActionPreference = "silentlyContinue"
    #$fromuser = "enzazadenclient"
    #$touser = "testusermagweg"  
    
    $fromuser =  read-host "From user " 
    $touser  = read-host "To user " 
    
    #check to see if the users exist 
    $User = Get-ADUser -LDAPFilter "(sAMAccountName=$fromuser)"
    If ($User  -eq $Null) {
        write-host "User $fromuser does not exist in AD"
        pause
        exit
        }
    $User = Get-ADUser -LDAPFilter "(sAMAccountName=$touser)"
    If ($User  -eq $Null) {
        write-host "User $touser does not exist in AD"
        pause
        exit
        }
    write-host "Copying Groups from $fromuser to $touser" 
    
        
    $groups = Get-ADPrincipalGroupMembership $fromuser
        $groups | ForEach-Object{
        $group = $_.name
        $members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty Name
            Write-verbose   "processing group $_.name"
            If ($members -contains $touser) {
                  Write-verbose   "  ..$touser already exists in the group $_.name"
             } Else {
                  write-host "  ..Adding $touser to group $_.name"    
                  Add-ADGroupMember $_.name -Members $touser
            }
    
    
    
        }
    write-host "done copying groups" 
    pause
    
    