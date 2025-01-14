﻿Import-Module AU

$releases_by_channel = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"

function global:au_BeforeUpdate {
  Get-RemoteFiles -Purge -NoSuffix
}

function global:au_SearchReplace {
  @{
    ".\legal\VERIFICATION.txt"      = @{
      "(?i)(^\s*location on\:?\s*)\<.*\>" = "`${1}<$($Latest.ReleasesUrl)>"
      "(?i)(\s*32\-Bit Software.*)\<.*\>" = "`${1}<$($Latest.URL32)>"
      "(?i)(^\s*checksum\s*type\:).*"     = "`${1} $($Latest.ChecksumType32)"
      "(?i)(^\s*checksum(32)?\:).*"       = "`${1} $($Latest.Checksum32)"
    }
    ".\tools\chocolateyInstall.ps1" = @{
      "(?i)(^\s*file\s*=\s*`"[$]toolsDir\\).*" = "`${1}$($Latest.FileName32)`""
    }
  }
}

function global:au_GetLatest {
  $releases_object = Invoke-RestMethod -Uri $releases_by_channel

  $stable_version = Get-Version $releases_object.channels.Stable.version

  $win32index = $releases_object.channels.Stable.downloads.chromedriver.platform.IndexOf('win32')
  $win64index = $releases_object.channels.Stable.downloads.chromedriver.platform.IndexOf('win64')

  $win32url = $releases_object.channels.Stable.downloads.chromedriver.url.Get($win32index)
  $win64url = $releases_object.channels.Stable.downloads.chromedriver.url.Get($win64index)

  $chrome_for_testing_dashboard = "https://googlechromelabs.github.io/chrome-for-testing/"

  $streams = @{}

  $streams[[string]"$stable_version.Version.Major"] = @{
    URL32           = $win32url
    URL64           = $win64url
    Version         = $stable_version
    ReleasesUrl     = $chrome_for_testing_dashboard
    FileType        = 'zip'
  }

  return @{ Streams = $streams }
}

update -ChecksumFor none
