﻿add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

<#
  .SYNOPSIS
    Push Messages to VMware vRealize Log Insight.
  
  .DESCRIPTION
  	Push Messages to VMware vRealize Log Insight.

  .EXAMPLE
    Push-vLIMessage -vLIServer "loginsight.lan.local -vLIAgentID "12862842-5A6D-679C-0E38-0E2BE888BB28" -Text "My Test"
	
  .EXAMPLE
    Push-vLIMessage -vLIServer "loginsight.lan.local -vLIAgentID "12862842-5A6D-679C-0E38-0E2BE888BB28" -Text "My Test" -Hostname MyTEST -FieldName myTest -FieldContent myTest
	
  .PARAMETER vLIServer
    Specify the vLI FQDN	

  .PARAMETER vLIAgentID
    Specify the vLI Agent ID

  .PARAMETER Text
    Specify the Event Text

  .PARAMETER Hostname
    Specify the Hostanme displayed in vLI

  .PARAMETER FieldName
    Specify the a Optinal Field Name for vLI
	
  .PARAMETER FieldContent
    Specify the a Optional FieldContent for the Field in -FieldName for vLI
	If FielName is missing and FieldContent is given, it will be ignored
	
 #Requires PS -Version 2.0
 
 #>
function Push-vLIMessage {

	[cmdletbinding()]
	param (
	[parameter(Mandatory=$true)]
	[string]$Text,
	[parameter(Mandatory=$true)]
	[string]$vLIServer,
	[parameter(Mandatory=$true)]
	[string]$vLIAgentID,
	[parameter(Mandatory=$false)]
	[string]$Hostname = $env:computername,
	[parameter(Mandatory=$false)]
	[string]$FieldName,
	[parameter(Mandatory=$false)]
	[string]$FieldContent = ""
	)
	Process {
		$Field_vLI = [ordered]@{
						name = "PS_vLIMessage"
						content = "true"
						}
		$Field_HostName = [ordered]@{
						name = "hostname"
						content = $Hostname
						}
					
		$Fields = @($Field_vLI, $Field_HostName)
		
		if ($FieldName) {
			$Field_Custom = [ordered]@{
					name = $FieldName
					content = $FieldContent
					}
			$Fields += @($Field_Custom)
			}
			
		$Restcall = @{
					messages =    ([Object[]]([ordered]@{
							text = ($Text)
							fields = ([Object[]]$Fields)
							}))
					} | convertto-json -Depth 4
	
		$Resturl = ("http://" + $vLIServer + ":9000/api/v1/messages/ingest/" + $vLIAgentID)
		try
		{
			$Response = Invoke-RestMethod $Resturl -Method Post -Body $Restcall -ContentType 'application/json' -ErrorAction stop
			Write-Information "REST Call to Log Insight server successful"
			Write-Verbose $Response
		}
		catch
		{
			Write-Error "REST Call failed to Log Insight server"
			Write-Verbose $error[0]
			Write-Verbose $Resturl
		}
	}
}