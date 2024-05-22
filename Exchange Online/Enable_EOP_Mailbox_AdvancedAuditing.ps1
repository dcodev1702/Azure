<#
    Author: @NathanMcNulty
    Date: 22 May 2024
    Description: This script enables advanced auditing for all user mailboxes in Exchange Online.
    The script also validates the advanced auditing settings for each mailbox.

    Sources:
    https://x.com/NathanMcNulty/status/1793174535556276507
    https://techcommunity.microsoft.com/t5/security-compliance-and-identity/increased-security-visibility-through-new-standard-logs-in/ba-p/4144454
    https://learn.microsoft.com/en-us/purview/audit-log-retention-policies?tabs=microsoft-purview-portal
#>

# Requires ExchangeOnlineManagement

# Connect to Exchange Online (uncomment the line below if you're not logged in to Exchange Online via PowerShell)
# Connect-ExchangeOnline

# Get all Mailboxes within Exchange Online
$Mailboxes = (Get-Mailbox -ResultSize Unlimited -Filter { RecipientType -eq "UserMailbox" -and RecipientTypeDetails -ne "DiscoveryMailbox"}).PrimarySmtpAddress

# Enable all advanced auditing on all Exchange Online Mailboxes
$Mailboxes | ForEach-Object {
    Write-Output $_
    Set-Mailbox -Identity $_ -AuditEnabled $true -AuditLogAgeLimit 365 -AuditAdmin @{add='Update, Copy, Move, MoveToDeletedItems, SoftDelete, HardDelete, FolderBind, SendAs, SendOnBehalf, Create, UpdateFolderPermissions, AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, UpdateInboxRules, UpdateCalendarDelegation, RecordDelete, ApplyRecord, MailItemsAccessed, UpdateComplianceTag, Send, AttachmentAccess, PriorityCleanupDelete, ApplyPriorityCleanup'} -AuditDelegate @{add='Update, Move, MoveToDeletedItems, SoftDelete, HardDelete, FolderBind, SendAs, SendOnBehalf, Create, UpdateFolderPermissions, AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, UpdateInboxRules, RecordDelete, ApplyRecord, MailItemsAccessed, UpdateComplianceTag, AttachmentAccess, PriorityCleanupDelete, ApplyPriorityCleanup'} -AuditOwner @{add='Update, Move, MoveToDeletedItems, SoftDelete, HardDelete, Create, MailboxLogin, UpdateFolderPermissions, AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, UpdateInboxRules, UpdateCalendarDelegation, RecordDelete, ApplyRecord, MailItemsAccessed, UpdateComplianceTag, Send, SearchQueryInitiated, AttachmentAccess, PriorityCleanupDelete, ApplyPriorityCleanup'}
}

# Validate advanced auditing settings
$Mailboxes | ForEach-Object { 
    Write-Host $_ -ForegroundColor Green
    (Get-Mailbox -Identity $_).AuditOwner
}
