


[cmdletbinding()]
Param
(
    $ComputerName = $env:COMPUTERNAME,
    [Parameter()][validateset('D','U','S','P')]
    $Environment = 'S',
    [Parameter()][validateset('Dev','Uat','PS','')]
    $Environment_URL = 'PS',
    $LogPath = 'C:\Temp\DSC_Logs',
    $OutputPath = [string]::format('C:\RSGMaint\PSDSC\mof_{0}',$Environment),
    $AppName1,
    $AppName2,
    $WebName1,
    $webName2,
    $ServiceName
    
)

#This creates metadata to modify the localconfiguration manager agent
[DSCLocalConfigurationManager()]
Configuration LocalConfigurationManagerPush
{
    Node $env:COMPUTERNAME
    {

        Settings
        {
            AllowModuleOverwrite = $true
            ConfigurationMode    = 'ApplyOnly'
            RefreshMode          = 'Push'
        }
    }
}

if(!(Test-Path -Path $path ))
{
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

#calling the configuration (same thing like calling a function) Creates meta mof file
LocalConfigurationManagerPush -OutputPath $path
#List of any modules needed for this configuration to work
$RequiredModules = @(
    'xWebAdministration',
    'xPSDesiredStateConfiguration',
    'xCertificate'
)

Import-Module -Name 'PSDesiredStateConfiguration'

Foreach($module in $RequiredModules)
{
    if(-not[boolean](Get-Module -Name $module -ListAvailable))
    {
        Write-Output "Installing $module"
        Install-Module -Name $module -Repository 'PSGallery' -Force -Verbose
    }
    Write-Output "Importing $module"
    Import-Module -Name $module -Verbose
}

# Add AD Group to Local admin
$Members  = @('domain\account1')
$Group = 'Administrators'
foreach ($user in $Members)
{
    if (-not[boolean](Get-LocalGroupMember -Name $Group -Member $user -ErrorAction SilentlyContinue))
    {
        Write-Output "Adding $user to $Group"
        Add-LocalGroupMember -Group $Group -Member $user
    }
    else
    {
        Write-Output "$user already exist in $Group"
    }
}
$SelfsignedCertificate = (Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object { $_.FriendlyName -like "*domain*" }).Thumbprint

$ConfigurationData = @{
    AllNodes    = @(
        @{
            NodeName = $ComputerName
            Features = @(
                "Web-Server",
                "Web-WebServer",
                "Web-Common-Http",
                "Web-Default-Doc",
                "Web-Dir-Browsing",
                "Web-Http-Errors",
                "Web-Static-Content",
                "Web-Http-Redirect",
                "Web-Health",
                "Web-Http-Logging",
                "Web-Log-Libraries",
                "Web-Performance",
                "Web-Stat-Compression",
                "Web-Security",
                "Web-Filtering",
                "Web-Windows-Auth",
                "Web-App-Dev",
                "Web-Net-Ext45",
                "Web-AppInit",
                "Web-ASP",
                "Web-Asp-Net45",
                "Web-CGI",
                "Web-ISAPI-Ext",
                "Web-ISAPI-Filter",
                "Web-Mgmt-Tools",
                "Web-Mgmt-Console",
                "NET-Framework-Features",
                "NET-Framework-Core",
                "NET-Framework-45-Features",
                "NET-Framework-45-Core",
                "NET-Framework-45-ASPNET",
                "NET-WCF-Services45",
                "NET-WCF-TCP-PortSharing45"
            )
            SiteInfo = @{
                sites = @(
                    @{
                        WebsiteName  = [string]::Format('{0}_{1}',$AppName1,$Environment);
                        physicalPath = [string]::Format('C:\Webs\{0}_{1}',$AppName1,$Environment);
                        Url          = [string]::Format('{0}-{1}.contoso.com',$AppName1,$Environment_URL)
                        bindings     = @(
                            @{
                                protocol  = 'http';
                                ipAddress = '*';
                                port      = 80
                            },
                            @{
                                protocol  = 'https';
                                ipAddress = '*';
                                port      = 443;
                            }
                        )
                    },
                    @{
                        WebsiteName  = [string]::Format('{0}_{1}',$WebName1,$Environment);
                        physicalPath = [string]::Format('C:\Webs\{0}_{1}',$WebName1,$Environment);
                        Url          = [string]::Format('{0}-{1}.contoso.com',$WebName1,$Environment_URL)
                        bindings     = @(
                            @{

                                protocol  = 'http';
                                ipAddress = '*';
                                port      = 80
                            },
                            @{
                                protocol  = 'https';
                                ipAddress = '*';
                                port      = 443;
                            }
                        )
                    },
                    @{
                        WebsiteName  = [string]::Format('{0}_{1}',$WebName2,$Environment);
                        physicalPath = [string]::Format('C:\Webs\{0}_{1}',$WebName2,$Environment);
                        Url          = [string]::Format('{0}-{1}.contoso.com',$WebName2,$Environment_URL)
                        bindings     = @(
                            @{

                                protocol  = 'http';
                                ipAddress = '*';
                                port      = 80
                            },
                            @{
                                protocol  = 'https';
                                ipAddress = '*';
                                port      = 443;
                            }
                        )
                    },
                    @{
                        WebsiteName  = [string]::Format('{0}_{1}',$AppName2,$Environment);
                        physicalPath = [string]::Format('C:\Webs\{0}_{1}',$AppName2,$Environment);
                        Url          = [string]::Format('{0}-{1}.contoso.com',$AppName2,$Environment_URL)
                        bindings     = @(
                            @{

                                protocol  = 'http';
                                ipAddress = '*';
                                port      = 80
                            },
                            @{
                                protocol  = 'https';
                                ipAddress = '*';
                                port      = 443;
                            }
                        )
                    }
                )
                appPool = @(
                    @{
                        AppPoolName           = [string]::Format('{0}_App_{1}',$AppName1,$Environment);
                        # Use empty string to set "No Managed Code"
                        managedRuntimeVersion = '' ;# Set to null for dotnet core application
                        managedPipelineMode   = 'Integrated';
                        enable32BitAppOnWin64 = $false;
                    },
                    @{
                        AppPoolName           = [string]::Format('{0}_Web_{1}',$WebName1,$Environment);
                        managedRuntimeVersion = 'v4.0' ;
                        managedPipelineMode   = 'Classic';
                        enable32BitAppOnWin64 = $false;
                    },
                    @{
                        AppPoolName           = [string]::Format('{0}_App_{1}',$AppName2,$Environment);
                        managedRuntimeVersion = '' ;# Set to null for dotnet core application
                        managedPipelineMode   = 'Integrated';
                        enable32BitAppOnWin64 = $false;
                    },
                    @{
                        AppPoolName           = [string]::Format('{0}_Web_{0}',$WebName2,$Environment);
                        managedRuntimeVersion = '' ; # Set to null for dotnet core application
                        managedPipelineMode   = 'Integrated';
                        enable32BitAppOnWin64 = $false;
                    }
                )
                server = @(
                    @{
                        User  = 'domain\serviceaccount'
                        GroupName = 'Administrators'
                    }
                )
                Service = @(
                    @{
                        Name  = [string]::format('{0}_{1}',$ServiceName,$Environment)
                        DisplayName = [string]::format('ServiceName_{0}',$ServiceName,$Environment)
                        StartUpType = 'Manual'
                        Path = [string]::format('C:\Webs\Microworkers_{0}\Parser\{1}\{1}.exe',$Environment,$ServiceName)
                        Description = [string]::format('{0} background service',"$ServiceName,$Environment")
                    }
                )
            }
        }
    )

    NonNodeData = @{
        #OtherData = import-csv -path ""
    }
}
Configuration ConfigureEnvironment
{
    Import-DscResource -Module PsDesiredStateConfiguration,xWebAdministration

    Node $AllNodes.NodeName
    {
        
        File LogPath
        {
            Ensure          = 'Present'
            DestinationPath = $LogPath
            Type            = 'Directory'
        }
        File OutputPath
        {
            Ensure          = 'Present'
            DestinationPath = $OutputPath
            Type            = 'Directory'
        }
        File EDESource-Temp
        {
            Ensure          = 'Present'
            DestinationPath = 'C:\ede-source\temp'
            Type            = 'Directory'
        }
        File EDESource-Upload
        {
            Ensure          = 'Present'
            DestinationPath = 'C:\ede-source\upload'
            Type            = 'Directory'
        }
        File ([string]::format('Directory_ExecutiveParser_{0}',$Environment))
        {
            Ensure          = 'Present'
            DestinationPath = (split-path -path $Node.SiteInfo.Service.Path)
            Type            = 'Directory'
        }
        Service ([string]::format('ExecutiveParser_{0}',$Environment))
        {
            Name        = $Node.SiteInfo.Service.Name
            StartupType = $Node.SiteInfo.Service.StartupType
            State       = 'Stopped'
            Description = $Node.SiteInfo.Service.Description
            DisplayName = $Node.SiteInfo.Service.DisplayName
            Path        = $Node.SiteInfo.Service.Path
            Ensure      = 'Present'
        }

        $Node.SiteInfo.sites.foreach(
            {
                $guid = [guid]::NewGuid()
                File "$($_.WebsiteName_Path)-$guid"
                {
                    DestinationPath = $_.physicalPath
                    Ensure          = 'Present'
                    Force           = $true
                    Type            = 'Directory'
                }
            }
        )

        $Node.Features.ForEach(
            {
                WindowsFeature $_
                {
                    Name    = $_
                    Ensure  = 'Present'
                    LogPath = "$LogPath\features.txt"
                    source  = 'C:\RSGMaint\EDE\sxs'
                }
            }
        )

        xWebsite Default
        {
            Ensure       = 'Absent'
            Name         = 'Default Web Site'
            PhysicalPath = 'C:\inetpub\wwwroot'
            DependsOn = '[WindowsFeature]Web-Server'
        }

        xWebAppPool DefaultAppPool
        {
            Ensure = 'Absent'
            Name   = 'DefaultAppPool'
        }
        xWebAppPool '.Net v4.5'
        {
            Name   = '.Net v4.5'
            Ensure = 'Absent'
        }
        xWebAppPool '.Net v4.5 Classic'
        {
            Name   = '.Net v4.5 Classic'
            Ensure = 'Absent'
        }

        Script 'removeServerHeader'
        {
            TestScript = {
                $parameters = @{
                    Pspath = 'MACHINE/WEBROOT/APPHOST'
                    Filter = "system.webServer/security/requestFiltering"
                    Name   = "removeServerHeader"
                }
                $GetRemoveServerHeader = Get-WebConfigurationProperty @parameters
                return ($GetRemoveServerHeader.value)
            }
            SetScript = {
                Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/security/requestFiltering" -name "removeServerHeader" -value "True"
            }
            GetScript = { 

                return @{
                    result = $GetRemoveServerHeader.Value
                }
            }
            DependsOn  = '[WindowsFeature]Web-Server'
        }

        $Node.SiteInfo.appPool.foreach(
            {
                $guid = [guid]::NewGuid()
                xWebAppPool "$($_.AppPoolName)-$guid"
                {
                    # xWebAppPool reference
                    # https://github.com/dsccommunity/xWebAdministration/blob/main/source/Examples/Resources/xWebAppPool/Sample_xWebAppPool.ps1
                    Name                           = $_.AppPoolName
                    Ensure                         = 'Present'
                    State                          = 'Started'
                    enable32BitAppOnWin64          = $_.enable32BitAppOnWin64
                    managedPipelineMode            = $_.managedPipelineMode
                    managedRuntimeVersion          = $_.managedRuntimeVersion
                }
            }
        )


        $Node.SiteInfo.sites.foreach(
            {
                $guid = [guid]::NewGuid()
                xWebsite "$($_.WebsiteName)-$guid"
                {
                    # xWebsite reference
                    # https://github.com/dsccommunity/xWebAdministration/tree/main/source/Examples/Resources/xWebSite
                    Name         = $_.WebsiteName
                    ApplicationPool = $_.WebSiteName
                    Ensure       =  'Present'
                    PhysicalPath = $_.physicalPath
                    State        = 'Started'
                    #DependsOn = '[WindowsFeature]Web-Server'
                    BindingInfo  = @(
                        MSFT_xWebBindingInformation
                        {
                            Hostname              = $_.Url
                            Protocol              = $_.bindings.protocol[0]
                            Port                  = $_.bindings.port[0]
                        }
                        MSFT_xWebBindingInformation
                        {
                            Hostname              = $_.Url
                            Protocol              = $_.bindings.protocol[1]
                            Port                  = $_.bindings.port[1]
                            CertificateThumbprint = $SelfsignedCertificate
                            CertificateStoreName  = 'MY'
                            sslflags               = '1'
                        }
                    )
                }
            }
        )

    }
}


ConfigureEnvironment -ConfigurationData $ConfigurationData -OutputPath $OutputPath -Verbose

Start-DscConfiguration -Path $OutputPath -Wait -Verbose -Force

