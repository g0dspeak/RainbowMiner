﻿using module ..\Include.psm1

param($Config)
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$MyConfig = $Config.Pools.$Name

$Request = [PSCustomObject]@{}

if(!$MyConfig.BTC) {
  Write-Log -Level Verbose "Pool Balance API ($Name) has failed - no wallet address specified."
  return
}

$OldEAP = $ErrorActionPreference
$ErrorActionPreference = "Stop"
try {
    $Request = Invoke-RestMethod "http://zpool.ca/api/walletEx?address=$($MyConfig.BTC)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool Balance API ($Name) has failed. "
}
$ErrorActionPreference = $OldEAP

if (($Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
    Write-Log -Level Warn "Pool Balance API ($Name) returned nothing. "
    return
}

[PSCustomObject]@{
  "currency" = $Request.currency
  "balance" = $Request.balance
  "pending" = $Request.unsold
  "total" = $Request.unpaid
  "payed" = $Request.total - $Request.unpaid
  "earned" = $Request.total
  "payouts" = @($Request.payouts | Select-Object)
  "lastupdated" = (Get-Date).ToUniversalTime()
}