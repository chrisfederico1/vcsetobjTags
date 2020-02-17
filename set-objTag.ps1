Function set-objTag()
{

<#
	.SYNOPSIS
    Apply Tag for the specified to object or VM's when using -VMHost. Pre Requisites all tags and Categories must be in vCenter.
    
	.DESCRIPTION
    This function imports the specified csv file then applies the appropriate tag for the specified object. Note if you just want to apply tags to a VM,host or Datastore
    use the -VIObject name parameter along with -CSVFILE. If using the -VMHost parameter with -CSVFILE then tags will be applied to all VM's on that host.
    **** Remember to .dot source
    .Example
    . .\set-objTag.ps1    *** Dot Source
    set-objTag -VIObject prdxmenu11 -CSVFILE fileName.csv     *** Applies tags to object
    set-objTag -VMHost VMHostname.vmware.com -CSVFILE filename.csv       *** This will apply tags to all VM's on this host.
	    
	.Notes
	NAME: set-objTag.ps1
    AUTHOR: Chris Federico  
	LASTEDIT: 02/13/2020
	VERSION: 1.0
	KEYWORDS: 

#>

# Parameters
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [string]$VIOBJECT,


    [Parameter(Mandatory=$false)]
    [string]$VMHost,


    [Parameter(Mandatory=$true)]
    [string]$CSVFILE
)

BEGIN {

# Clear Screen
Clear-Host

# Start the logger
Start-Transcript -path .\set-objTag-log.txt -Force
write-host "INFO: Importing CSV file...."

# Import csv file
$csv = import-csv $CSVFILE

# Create empty array of tags
$tags = @()


}

PROCESS{
  
    if ($VIObject -and $CSVFILE)
        {
            write-host "INFO: Ok we will apply the tags for " $VIObject "!" -ForegroundColor Yellow
            # Ask user if user wants to continue
            $reply = read-host "Continue?[y/n]"
            if ($reply -match "[nN]")
                {
                    exit
                }
        
            # Add tags that match Entity to array $tags    
            $tags += $csv | where-object{$_.Entity -match $VIObject}

            # Cycle thru each tag
        foreach ($tag in $tags)
            {
                # split Tag into 2 and get 0 for Category Name
                $Category = ($tag.tag -split '/')[0]
                # Split Tag into 2 and get 1 for Tag Name 
                $newtag = ($tag.tag -split '/')[1]
                
                # Get final tag information implement into new-tagassignment
                $finaltag = get-tag -Name $newtag -Category $Category
                
                # Apply tag . We need to split the tag field and grab the second element in array
                New-TagAssignment -Entity $tag.Entity -tag $finaltag -Confirm:$false -ErrorAction Stop                
            }
        

        }
    elseif ($VMHost -and $CSVFILE)
        {
            write-host "INFO: Ok apply tags for all VMs on " $VMHost "!" -ForegroundColor Yellow
            # Ask user if they want to continue
            $reply = read-host "Continue?[y/n]"
            if ($reply -match "[nN]")
                {
                    exit
                }

            # Get VMs on Host
            $vms = get-vmhost -Name $VMHost -ErrorAction Stop| Get-VM
            # Go thru each VM  
            foreach ($vm in $vms)
                {
                    write-host "INFO: Working on vm.... $vm" -ForegroundColor Green

                    # Add tags that match Entity to array $tags
                    $tags += $csv | where-object {$_.Entity -match $vm}

                    # Cycle thru each tag and apply them
                    foreach ($tag in $tags)
                    {
                    
                        # Split Tag into 2 and get 0 for Category Name
                        $Category = ($tag.tag -split '/')[0]
                        # Split Tag into 2 and get 1 for Tag Name 
                        $newtag = ($tag.tag -split '/')[1]
                
                        # Get final tag information implement into new-tagassignment
                        $finaltag = get-tag -Name $newtag -Category $Category

                        # Apply tag . We need to split the tag field and grab the second element in array
                        New-TagAssignment -Entity $tag.Entity -tag $finaltag -Confirm:$false -ErrorAction Stop

                    }
                }

        }
    else 
        {
            write-host "INFO: Please run script again with proper parameters. See help if needed help set-objtag "  -ForegroundColor Red
        }

       }
    



END
    {
        # Stop Logging
        Stop-Transcript

    }

}