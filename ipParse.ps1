$inputFile = 'ip_list.txt'
$outputFile = 'expanded_ip_list.txt'
$ipEntries = Get-Content -Path $inputFile
$expandedIPs = @()

foreach ($entry in $ipEntries) {
    $entry = $entry.Trim()
    if ($entry.Contains('-')) {
        # It's an IP range
        $parts = $entry.Split('-')
        $startIP = $parts[0]
        $endIP = $parts[1]
        
        # Extract the last octet of start and end IPs
        $startOctets = $startIP.Split('.')
        $endOctets = $endIP.Split('.')
        
        
        $baseIP = "$($startOctets[0]).$($startOctets[1]).$($startOctets[2])."

        # Get the last octet values as integers
        $startLastOctet = [int]$startOctets[3]
        $endLastOctet = [int]$endOctets[3]

        # Generate IPs in the range
        for ($i = $startLastOctet; $i -le $endLastOctet; $i++) {
            $expandedIPs += $baseIP + $i
        }
    }
    else {
        # It's a single IP
        $expandedIPs += $entry
    }
}

# Output the expanded list to a file
$expandedIPs | Set-Content -Path $outputFile

