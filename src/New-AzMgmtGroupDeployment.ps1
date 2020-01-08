function New-AzMgmtGroupDeployment {
    <#
        5/27/2019 - Kristian Nese, AzureCAT
        In anticipation of updated SDKs, this function can be used to target ARM deployments to a management group
        
        .Synopsis
        Deploys Azure Resource Manager template to a Management Group

        .Example
        New-AzMgmtGroupDeployment -Name <name> -Location <location> -MgmtGroupId <id> -TemplateFile <path> -ParameterFile <path>
    #>

    [cmdletbinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $TemplateFile,

        [string] $ParameterFile,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $MgmtGroupId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Location
    )
    begin {
        $currentContext = Get-AzContext
        $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        $profileClient = [Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient]::new($azureRmProfile)
        $token = $profileClient.AcquireAccessToken($currentContext.Subscription.TenantId)
    }
    process {
        if(!([string]::IsNullOrEmpty($ParameterFile)))
        {
            $TemplateParameters = Get-Content -Raw $ParameterFile | ConvertFrom-Json
        }
        else 
        {
        $body = @"
{
    "properties": {
        "template": $(Get-Content -Raw $TemplateFile),
        "parameters": $($TemplateParameters.parameters | ConvertTo-Json -Depth 100),
        "mode": "incremental"
    },
    "location": $($Location | ConvertTo-Json -Depth 100)
}
"@

    # ARM Request
    $ARMRequest = @{
        Uri = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$($MgmtGroupId)/providers/Microsoft.Resources/deployments/$($Name)?api-version=2019-05-01"
        Headers = @{
            Authorization = "Bearer $($token.AccessToken)"
            'Content-Type' = 'application/json'
        }
        Method = 'Put'
        Body = $body
        UseBasicParsing = $true
    }
    $Deploy = Invoke-WebRequest @ARMRequest
    #prettify
    [Newtonsoft.Json.Linq.JObject]::Parse($deploy.Content).ToString()
        }
    }
}

