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

Function Send {
    param (
        [parameter(Mandatory)][System.Net.HttpListenerResponse]$resp,
        [parameter(Mandatory)][byte[]]$data,
        [string]$contentType = [System.Net.Mime.MediaTypeNames+Text]::Html,
        [System.Text.Encoding]$contentEncoding = [System.Text.Encoding]::UTF8,
        [int]$statusCode = 200
    )

    try {
        $resp.StatusCode = $statusCode
        $resp.ContentType = $contentType
        $resp.ContentEncoding = $contentEncoding
        $resp.OutputStream.Write($data, 0, $data.Length)
    }
    catch {
        Write-Error $_
    }
    finally {
        $resp.Close()
    }
}

Function GetMimeType {
    param (
        [parameter(Mandatory)][string]$extension
    )

    $ext = $extension.ToLower()
    switch ($ext) {
        ".css" { "text/css"; Break }
        ".csv" { "text/csv"; Break }
        ".html" { [System.Net.Mime.MediaTypeNames+Text]::Html; Break }
        ".htm" { [System.Net.Mime.MediaTypeNames+Text]::Html; Break }
        ".js" { "text/javascript"; Break }
        ".rtf" { [System.Net.Mime.MediaTypeNames+Text]::RichText; Break }
        ".str" { [System.Net.Mime.MediaTypeNames+Text]::Html; Break }
        ".txt" { [System.Net.Mime.MediaTypeNames+Text]::Plain; Break }
        ".xhtml" { "application/xhtml+xml"; Break }
        ".xml" { [System.Net.Mime.MediaTypeNames+Text]::Xml; Break }

        ".gif" { [System.Net.Mime.MediaTypeNames+Image]::Gif; Break }
        ".ico" { "image/vnd.microsoft.icon"; Break }
        ".jpg" { [System.Net.Mime.MediaTypeNames+Image]::Jpeg; Break }
        ".jpeg" { [System.Net.Mime.MediaTypeNames+Image]::Jpeg; Break }
        ".png" { "image/png"; Break }
        ".svg" { "image/svg+xml"; Break }
        ".tiff" { [System.Net.Mime.MediaTypeNames+Image]::Tiff; Break }
        ".tif" { [System.Net.Mime.MediaTypeNames+Image]::Tiff; Break }

        ".gz" { "application/gzip"; Break }
        ".json" { "application/json"; Break }
        ".pdf" { "application/pdf"; Break }
        ".zip" { [System.Net.Mime.MediaTypeNames+Application]::Zip; Break }

        ".ttf" { "font/ttf"; Break }

        default { [System.Net.Mime.MediaTypeNames+Application]::Octet; Break }
    }

    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
    # System.Net.Mime.MediaTypeNames.Application.Octet
    # System.Net.Mime.MediaTypeNames.Application.Pdf
    # System.Net.Mime.MediaTypeNames.Application.Rtf
    # System.Net.Mime.MediaTypeNames.Application.Soap
    # System.Net.Mime.MediaTypeNames.Application.Zip
}

Function Log {
    param (
        [parameter(Mandatory)][string]$message,
        [string]$filePath = "webhost.log",
        [string]$dateTimeFormat = "u"
    )

    "$((Get-Date).ToString($dateTimeFormat)) $message" | Out-File -FilePath $filePath -Append
}

Function Start-WebHost {
    param
    (
        [ushort]$port = 2194 # Ports 2194-2196 are unassigned in IANA Service Name and Transport Protocol Port Number Registry
    )

    
    # Constants
    Set-Variable spaceByteArray -Option Constant -Value ([System.Text.Encoding]::UTF8.GetBytes(" "))
    Set-Variable waitTime -Option Constant -Value (New-Object -TypeName System.TimeSpan -ArgumentList 0,0,0,1,678)

    # Local variables
    $rootPath = (Get-Location).Path
    $prefix = "http://127.0.0.1:$port/"         # 127.0.0.1 is fairly universal
    $server = New-Object -TypeName System.Net.HttpListener
    $server.Prefixes.Add($prefix)
    Write-Debug "`$prefix        is $prefix" 

    if ($Debug) {
        $DebugPreference = 'Continue'           # Start - display debug messages
    }
  
    try {
        $server.Start()
        Write-Host "Server started.`nAccess server at: $prefix"
        while ($true) {
            # The synchronous version of GetContext will block until we get a request connection
            # This unfortuntately also blocks CTRL+C termination of PowerShell 
            # This is a behaviour which we do not want.
            # So we use the asynchronous version.
            Write-Host "Waiting for request"
            $ctxTask = $server.GetContextAsync()
  
            # Instead of directly busy spin, we add a blocking wait call
            while (-not $ctxTask.IsCompleted) {
                [void]$ctxTask.Wait($waitTime)
            }
  
            $ctx = $ctxTask.Result
  
            # Get corresponding requests and response objects
            [System.Net.HttpListenerRequest] $req = $ctx.Request
            [System.Net.HttpListenerResponse] $resp = $ctx.Response;
  
            # Resolve request into local path
            $localPath = "$rootPath$($req.Url.AbsolutePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))"
  
            if ([System.IO.File]::Exists($localPath)) {
                $ext = [System.IO.Path]::GetExtension($localPath)
                $mimeType = GetMimeType($ext)
  
                $data = Get-Content $localPath -AsByteStream -ReadCount 0

                # If file is empty, send a single character 'space' byte array
                if ($null -eq $data) {
                    $data = $spaceByteArray
                }

                Send $resp $data -contentType $mimeType
                Write-Host "Requesting: $($req.Url.AbsolutePath) ==> $localPath (200 $mimeType)"
            }
            else {
                $data = [System.Text.Encoding]::UTF8.GetBytes("404 - Resource not found.")
                Send $resp $data -statusCode 404
                Write-Host "Requesting: $($req.Url.AbsolutePath) ==> $localPath (404 $mimeType )"
            }
  
            # Dispose
            $ctxTask.Dispose()
        }

    }
    catch {
        Write-Error $_
    }
    finally {
        $server.Stop()
        Write-Host "Server stopped."
    }

    # End-of-script
    if ($Debug) {
        $DebugPreference = 'SilentlyContinue'   # End   - display debug messages
    }
}

# Module member export definitions
Export-ModuleMember -Function Start-WebHost