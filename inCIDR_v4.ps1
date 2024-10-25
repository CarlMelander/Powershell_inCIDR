# Set the script root directory
$scriptroot = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

# Import CSV files
$cidrRanges = Import-Csv -Path "$($scriptroot)\CIDR.csv" -Header "CIDR" -Encoding UTF8
$ipsToCheck = Import-Csv -Path "$($scriptroot)\IP.csv" -Header "IP" -Encoding UTF8


function Test-IPInCIDR {
    param (
        [string]$IPAddress,
        [string]$CIDR
    )

    # Split the CIDR notation into base address and prefix length
    $CIDRComponents = $CIDR.Split('/')
    if ($CIDRComponents.Count -ne 2) {
        Write-Error "Invalid CIDR format: $CIDR. Please use the format '192.168.1.0/24'."
        return $false
    }

    $BaseAddress = $CIDRComponents[0]
    $PrefixLength = [int]$CIDRComponents[1]

    # Convert IP addresses to byte arrays
    $IPBytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
    $BaseBytes = [System.Net.IPAddress]::Parse($BaseAddress).GetAddressBytes()

    # Buid out the netmask
    $NetmaskBytes = @()
    for ($i = 0; $i -lt 4; $i++) {
        $Bits = [Math]::Min([Math]::Max($PrefixLength - ($i * 8), 0), 8)
        $NetmaskBytes += [byte](0xFF -shr (8 - $Bits))
    }

    # Apply the masking
    for ($i = 0; $i -lt 4; $i++) {
        if (($IPBytes[$i] -band $NetmaskBytes[$i]) -ne ($BaseBytes[$i] -band $NetmaskBytes[$i])) {
            return $false
        }
    }

    return $true
}

$Results = @()

# Loop IP addresses
foreach ($IPEntry in $ipsToCheck) {
    $IP = $IPEntry.IP
    $MatchFound = $false
    $MatchingCIDR = 'na'

    # Loop CIDR ranges
    foreach ($CIDREntry in $cidrRanges) {
        $CIDR = $CIDREntry.CIDR
        if (Test-IPInCIDR -IPAddress $IP -CIDR $CIDR) {
            $MatchFound = $true
            $MatchingCIDR = $CIDR
            break 
        }
    }

    # Add the result to the PSOBJECT
    $Results += [PSCustomObject]@{
        IP             = $IP
        'Has Match'    = $MatchFound
        'Matching CIDR' = $MatchingCIDR
    }
}

# Output the results
$Results | Export-Csv -Path "$($scriptroot)\output.csv" -NoTypeInformation -Force
