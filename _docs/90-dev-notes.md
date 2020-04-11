# Dev notes

Publish-Module -Path 'D:\src\github.com\ongzhixian\pwsh-webhost\WebHost' -Repository 'pwsh-repository'

Install-Module 'WebHost' -Repository 'pwsh-repository'

Import-Module 'WebHost'

## Helper script

Script to delete module and re-import it.

Get-ChildItem 'D:\Apps\PwshRepository' | Where-Object { $_.Name -like 'WebHost*' } | ForEach-Object { Remove-Item $_ }
Publish-Module -Path 'D:\src\github.com\ongzhixian\pwsh-webhost\WebHost' -Repository 'pwsh-repository' -Force
Install-Module 'WebHost' -Repository 'pwsh-repository' -Force
Import-Module WebHost -Force