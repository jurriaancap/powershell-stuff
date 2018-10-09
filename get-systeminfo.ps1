function Get-SystemInfo {

<#
.SYNOPSIS
Retrieves a bunch of stuff.
.DESCRIPTION
Get-SystemInfo does not uses Windows Management Instrumentation
(WMI) to retrieve information from one or more computers.
Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses, up to a maximum
of 10.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers
that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name
to which failed computer names will be written. Defaults to
C:\Retry.txt.
.EXAMPLE
type this on youre machine in the powershell screen
Get-Content names.txt | Get-SystemInfo
.EXAMPLE
Get-SystemInfo -ComputerName SERVER1,SERVER2
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,HelpMessage="Computer name or IP address")]
        [ValidateCount(1,10)]
        [Alias('hostname')]
        [string[]]$ComputerName,
        [Parameter(HelpMessage="PATH and filename of the errorlog")]
        [string]$ErrorLog = 'c:\tmp\errorlog.log' ,
        [switch]$LogErrors
    )
    BEGIN {
    Write-Verbose "Error log will be $ErrorLog"
    }
    PROCESS {
        foreach ($computer in $ComputerName) {
            Write-Verbose "Querying $computer"
            Try {
                $everything_ok = $true
                $now = (Get-Date -format o).ToString()
                $os = get-service -computerName $computer -ErrorAction Stop
            
            } catch {
                $everything_ok = $false
                Write-Warning "$computer failed"
                 if ($logerrors) {
                     "$now :- ERROR: processing $computer - MSG: $_" | out-file $errorlog -append 
                     Write-Warning "logged to $errorlog"
                     
                }
            }
            if ($everything_ok) {
                $comp = get-service -computerName $computer
                $bios = get-service -computerName $computer
                $props = @{'sysMachinename' = $os[0].machinename;
                           'sysservicename'  = $os[0].servicename;
                           'syserrorlog' = $errorlog 
                          }
                Write-Verbose "service queries complete"
                $obj = new-object -TypeName PSobject -Property $props
                write-output $obj
                # write-output $os[0]
            }
        }
    }
    END {}
}

#Get-SystemInfo -computername localhost
#'localhost2' | get-systeminfo

Get-SystemInfo –computername NOTONLINE,testje,localhost -logerrors -verbos

