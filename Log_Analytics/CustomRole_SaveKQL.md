# Create Azure Custom RBAC Role: Log Analytics – Save KQL Queries

This repository defines and documents a **least-privilege Azure RBAC custom role** that allows users to:

- Run KQL queries against Log Analytics data
- Read all log table data
- Save KQL queries to a **Query Pack**
- **Without** modifying workspace settings, tables, or Azure resources
- Import Azure RBAC Custom Role (JSON) -> [Click Here!](https://github.com/dcodev1702/Azure/blob/main/Log_Analytics/rbac_custom_role_kql_save_query.json) 


## ⚠️ Prerequisite (MANDATORY)

> **A privileged user must create the Log Analytics Workspace and the Query Pack first.**

Before assigning this role to any user:

- The **Log Analytics Workspace** **must already exist**
- The **Query Pack** **must already exist**
- Both resources **must be created by a privileged role** such as:
  - **Owner**
  - **Contributor**
  - **Log Analytics Contributor**
  - **Azure Monitor Contributor**

This custom role **does NOT** allow:
- Creating Log Analytics Workspaces
- Creating Query Packs
- Creating or modifying Resource Groups

It is strictly for **query execution and query saving only**.

---

## Why Resource Group–Level Assignment Is Required

Azure RBAC is **hierarchical**:

```

Subscription
└── Resource Group
└── Log Analytics Workspace
└── Query Pack

````

When a user saves a KQL query in the **Logs** experience, Azure must:

1. Traverse the **Resource Group**
2. Discover the **Query Pack**
3. Write the query into that pack

If the user is scoped **only to the Log Analytics Workspace**, Azure cannot traverse the Resource Group, which results in misleading errors such as:

- `403 Forbidden`
- “You need permission to create resource groups”
- “querypacks/queries/action not authorized”

**Assigning the role at the Resource Group scope resolves this correctly and securely.**

---

## Custom Role Definition

This is the **authoritative role definition** used by this solution.

```json
{
  "properties": {
    "roleName": "Log Analytics - Save KQL Queries",
    "description": "This is a custom role designed to allow a user to read tables via KQL and save KQL Queries.",
    "assignableScopes": [
      "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/secops"
    ],
    "permissions": [
      {
        "actions": [
          "Microsoft.Resources/subscriptions/resourceGroups/read",
          "Microsoft.OperationalInsights/workspaces/read",
          "Microsoft.OperationalInsights/workspaces/query/read",
          "Microsoft.OperationalInsights/workspaces/savedSearches/*",
          "Microsoft.OperationalInsights/queryPacks/read",
          "Microsoft.OperationalInsights/queryPacks/queries/read",
          "Microsoft.OperationalInsights/queryPacks/queries/write",
          "Microsoft.OperationalInsights/queryPacks/queries/action"
        ],
        "notActions": [],
        "dataActions": [
          "Microsoft.OperationalInsights/workspaces/tables/data/read"
        ],
        "notDataActions": []
      }
    ]
  }
}
````

---

## Correct Role Assignment (MANDATORY)

### ✅ Assign at the **Resource Group** scope

```
/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/secops
```

### Azure Portal Steps

1. Go to **Resource Groups**
2. Select **secops** or the name of your resource group
3. Open **Access control (IAM)**
4. Click **Add role assignment**
5. Select **Log Analytics – Save KQL Queries**
6. Add the user
7. Save

> ⚠️ **Credential refresh required**
> Users must **sign out and sign back in** after role assignment.

---
<img width="2211" height="648" alt="image" src="https://github.com/user-attachments/assets/c321c8d4-d98e-4281-8890-43f3a891e38b" />

<img width="1814" height="1212" alt="image" src="https://github.com/user-attachments/assets/83f15e47-b622-4f86-9796-9820b806fc7d" />

<img width="1551" height="1098" alt="image" src="https://github.com/user-attachments/assets/f54b4cfd-271b-45d8-8083-c59467309502" />

<img width="1810" height="691" alt="image" src="https://github.com/user-attachments/assets/2c07aab6-9b7f-4dee-9c3a-2046b44674cb" />


## ❌ What NOT to do

### ❌ Do NOT assign this role here:

```
Log Analytics Workspace → Access control (IAM)
```

Workspace-level assignment:

* Breaks Query Pack discovery
* Causes 403 errors when saving queries
* Violates Azure RBAC traversal requirements
* Is unnecessary due to permission inheritance

If the user was previously added at the workspace level, **remove that assignment**.

---

## Final Expected State (Correct)

| Scope                   | Role Assignment                    |
| ----------------------- | ---------------------------------- |
| Resource Group `secops` | ✅ Custom Role Assigned             |
| Log Analytics Workspace | ❌ No direct assignment             |
| Query Pack              | ❌ No direct assignment (inherited) |

---

## Capabilities Granted

| Capability                     | Allowed |
| ------------------------------ | ------- |
| Run KQL queries                | ✅       |
| Read log table data            | ✅       |
| Save KQL queries to Query Pack | ✅       |
| Modify workspace settings      | ❌       |
| Modify tables / ingestion      | ❌       |
| Create resources               | ❌       |

---

## Design Notes

* Query Packs **must reside in the same Resource Group** as the Log Analytics Workspace
* All saved queries should target the **SecOps-owned Query Pack**
* This model aligns with Azure Monitor RBAC and Azure Resource Manager traversal rules
* This is the **minimum required permission set** for KQL authors

---

## Troubleshooting Checklist

If saving a query fails:

* [ ] Was the Log Analytics Workspace created by a privileged user?
* [ ] Was the Query Pack created by a privileged user?
* [ ] Is the role assigned at the **Resource Group**, not the workspace?
* [ ] Does the user have `resourceGroups/read`?
* [ ] Is the Query Pack in the `secops` resource group?
* [ ] Has the user refreshed credentials?

---

## Security Posture

This role is intentionally strict.

* No Contributor
* No Owner
* No workspace configuration
* No table modification
* No resource creation

Any deviation from this design should be documented and approved.

---

## Maintainers

This repository defines a **production-grade RBAC model**.

Do not widen scope or permissions without security review.
