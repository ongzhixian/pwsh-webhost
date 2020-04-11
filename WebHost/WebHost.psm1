<#
 .Synopsis
  Start a HTTP server to host a web site.

 .Description
  Start a HTTP web server to host a web site.

 .Parameter Port
  The port that HTTP server will use to host the web site.
  Defaults to 2194

#   .Parameter Host
#   The host that HTTP server will use to host the web site.
#   Defaults to localhost

#  .Parameter Wwwroot
#   The directory to use as root directory to serve files from.
#   Defaults to the folder that command was executed from.

 .Example
   # Start HTTP server to host web site using default settings
   Start-WebHost

#  .Example
#    # Display a date range.
#    Show-Calendar -Start "March, 2010" -End "May, 2010"

#  .Example
#    # Highlight a range of days.
#    Show-Calendar -HighlightDay (1..10 + 22) -HighlightDate "December 25, 2008"
#>
Function Start-WebHost {
    param
    (
        [ushort]$port = 2194 # Ports 2194-2196 are unassigned in IANA Service Name and Transport Protocol Port Number Registry
        # [DateTime] $start = [DateTime]::Today,
        # [DateTime] $end = $start,
        # $firstDayOfWeek,
        # [int[]] $highlightDay,
        # [string[]] $highlightDate = [DateTime]::Today.ToString()
    )
    
    Write-Host "Working 789"
}

# Module member export definitions
Export-ModuleMember -Function Start-WebHost