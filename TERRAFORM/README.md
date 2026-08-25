# AI-901 demo "backup" Terraform

A trainer-only fallback environment for **AI-901: Introduction to AI in Azure**. In class the trainer
builds everything live from scratch in [Microsoft Foundry](https://ai.azure.com); this stack stands up
the same environment in a **completed, demo-ready** state (resources **and** data plane) so every
module demo shows real results immediately if the live build fails.

> Not attendee-facing. Keep this folder and its docs out of the attendee README.

## What it deploys

A single **Microsoft Foundry** (`kind = AIServices`, project-enabled) account + project hosts every
service the course demos — Azure OpenAI, Azure AI Language, Speech, Vision, and Content Understanding —
plus model deployments and a Content Understanding analyzer.

| Resource | Purpose (module) |
| --- | --- |
| `azurerm_resource_group.rg` (`AI901-<postfix>`) | Holds the backup environment |
| `azurerm_resource_group.demo_rg` (`Demo<postfix>`) | Empty RG for the live from-scratch build |
| `azurerm_cognitive_account.foundry` (AIServices) + `_project` | Foundry account/project (M1) |
| `azurerm_cognitive_deployment.gpt` = **gpt-5.4-mini** (`current`) or **gpt-5-mini** (`parity`) | Chat / agents / text / vision (M1, M2, M3, M5) |
| `azurerm_cognitive_deployment.cu_completion` = **gpt-5.2** | Content Understanding completion model (M6) |
| `azurerm_cognitive_deployment.embedding` = **text-embedding-3-large** | Content Understanding embeddings (M6) |
| `azurerm_cognitive_deployment.image` = **gpt-image-2** *(toggle)* | Image generation (M5) — GA; gated by `enable_image_generation` |
| `azurerm_storage_account.default` + containers | Sample receipts (M6) and images (M5) |
| Content Understanding analyzer `ai901receiptanalyzer` | Custom receipt field-extraction demo (M6) |

Speech (M4), Language (M3), and Vision image **analysis** (M5) need **no extra resources** — they're
exposed by the same multi-service Foundry account and demoed live in the portal/playground. Image
**generation** (M5) is deployed by default (`gpt-image-2`, GA) unless you disable
`enable_image_generation`. Video generation is intentionally **out of scope** for this backup stack:
the prior Sora path was removed because `sora-2` is Preview, its target catalog retires 2026-09-15,
and there is no GA video-generation successor to pin today. Keep M5 video-generation coverage
conceptual unless a current GA replacement becomes available.

## Entra ID (AAD) only — no keys

Company policy forbids account/access keys, so the whole stack is key-less:

- Storage: `shared_access_key_enabled = false`; provider `storage_use_azuread = true`; containers
  created via the management plane (`storage_account_id`); the upload script uses `az ... --auth-mode login`.
- Foundry (AI Services): `local_auth_enabled = false` + `custom_subdomain_name` (regional endpoints
  reject Entra ID tokens, so the custom subdomain is required).
- The data plane authenticates with `az account get-access-token` (AAD bearer tokens) and **retries on
  401/403** to absorb RBAC propagation. The deployer gets **Storage Blob Data Contributor** and
  **Cognitive Services User** role assignments.

## Prerequisites

- **Terraform** >= 1.5, **Azure CLI** (`az`), **PowerShell 7** (`pwsh`).
- `az login` to a subscription **with model quota** in **`eastus2`** for the selected chat profile
  (`gpt-5.4-mini` for `model_profile=current`, `gpt-5-mini` for `model_profile=parity`), plus
  `gpt-5.2`, `text-embedding-3-large`, and optionally `gpt-image-2`.
- The signed-in principal must be able to create role assignments (Owner / User Access Administrator)
  on the new resource group.

> If `az` runs under a different identity than Terraform (e.g. a service principal), set
> `-var deployer_object_id=<the az login object id>` so the data-plane RBAC targets the right principal.

## Deploy

**Step 0 (required):** run the preflight before `plan`/`apply`. It verifies the **exact catalog
version + SKU**, **GA lifecycle**, **SKU retirement**, and **incremental quota** for the selected
deployment profile.

- Every preflight-affecting script argument must exactly match the values you pass to
  `terraform plan` / `terraform apply`. Do **not** sync only `ModelProfile`; mirror every override.
  The matching pairs are:

  | Preflight script | Terraform |
  | --- | --- |
  | `-ModelProfile` | `-var model_profile` |
  | `-EnableImageGeneration` | `-var enable_image_generation` |
  | `-ChatCapacity` | `-var chat_capacity` |
  | `-CuCompletionCapacity` | `-var cu_completion_capacity` |
  | `-EmbeddingCapacity` | `-var embedding_capacity` |
  | `-ImageModelName` | `-var image_model_name` |
  | `-ImageModelVersion` | `-var image_model_version` |
  | `-ImageCapacity` | `-var image_capacity` |

- For a **fresh deployment**, omit `-TargetResourceGroupName` and `-TargetAccountName`. The preflight
  then treats the full requested capacity as new quota demand.

- For a **re-apply against the exact Foundry account this Terraform stack already controls**, pass
  **both** `-TargetResourceGroupName` and `-TargetAccountName` so the preflight can subtract only the
  matching existing Terraform deployments when it calculates **incremental** quota demand. These are
  optional **preflight-only** inputs, **not** Terraform variables, and they must point at the exact
  account managed by this stack.

- Default `model_profile=current`:

  ```powershell
  cd TERRAFORM
  az login
  pwsh -NoProfile -File scripts\Test-ModelAvailability.ps1
  terraform init
  terraform plan  -var group_postfix=0609     # confirm names like AI901-0609
  terraform apply -var group_postfix=0609
  ```

- Only if Terraform will also use `-var model_profile=parity`:

  ```powershell
  cd TERRAFORM
  az login
  pwsh -NoProfile -File scripts\Test-ModelAvailability.ps1 -ModelProfile parity
  terraform init
  terraform plan  -var group_postfix=0609 -var model_profile=parity
  terraform apply -var group_postfix=0609 -var model_profile=parity
  ```

- If you override Terraform values, mirror them in the preflight call. For example, to disable image
  generation in both places:

  ```powershell
  cd TERRAFORM
  az login
  pwsh -NoProfile -File scripts\Test-ModelAvailability.ps1 -EnableImageGeneration:$false
  terraform init
  terraform plan  -var group_postfix=0609 -var enable_image_generation=false
  terraform apply -var group_postfix=0609 -var enable_image_generation=false
  ```

- If you are re-applying to an existing Terraform-managed account, add the target account identifiers
  only to the preflight call. Example:

  ```powershell
  cd TERRAFORM
  az login
  pwsh -NoProfile -File scripts\Test-ModelAvailability.ps1 `
    -TargetResourceGroupName AI901-0609 `
    -TargetAccountName ai901-0609-foundry-fnd
  terraform init
  terraform plan  -var group_postfix=0609
  terraform apply -var group_postfix=0609
  ```

The preflight values and Terraform values **must match exactly** for every overridden knob.

`apply` provisions the resources, then runs the data-plane scripts automatically:

1. `scripts/upload-sample-data.ps1` — uploads `sample-data/` to blob storage (AAD).
2. `scripts/create-cu-analyzer.ps1` — sets Content Understanding default model deployments and creates
   the `ai901receiptanalyzer` custom analyzer.

To re-run only the data plane (e.g. after editing a script), taint it:

```powershell
terraform apply -replace='terraform_data.create_cu_analyzer[0]' -var group_postfix=0609
```

Disable the data plane entirely with `-var enable_data_plane=false`.

## Verify

```powershell
terraform output                       # foundry_endpoint, deployments, analyzer id
az cognitiveservices account deployment list -g AI901-0609 -n <foundry_name> -o table
```

In the [Foundry portal](https://ai.azure.com): the project shows **four** deployments by default
(the selected chat model, `gpt-5.2`, `text-embedding-3-large`, `gpt-image-2`). If
`enable_image_generation=false`, expect **three**. Content Understanding lists the
`ai901receiptanalyzer` analyzer — run it against a file in the `sample-documents` container to see
extracted receipt fields.

## Destroy

```powershell
terraform destroy -var group_postfix=0609
```

## Variables

| Variable | Default | Notes |
| --- | --- | --- |
| `group_postfix` | _(required)_ | 1–10 lowercase alphanumerics; drives all resource names |
| `model_profile` | `current` | Chat-model profile: `current` = `gpt-5.4-mini` (`2026-03-17`, GA to 2027-09-21); `parity` = `gpt-5-mini` (`2025-08-07`, GA to 2027-02-09) to mirror the upstream lab |
| `chat_capacity` | `30` | Selected chat-profile TPM (thousands) |
| `cu_completion_capacity` | `10` | gpt-5.2 TPM for Content Understanding |
| `embedding_capacity` | `30` | text-embedding-3-large TPM |
| `enable_image_generation` | `true` | Deploy the gpt-image-2 image model (M5). Disable if no image quota in the region |
| `image_model_name` | `gpt-image-2` | Image-generation model (GA) |
| `image_model_version` | `2026-04-21` | Version for `image_model_name` |
| `image_capacity` | `1` | Image deployment capacity (image models share a small per-region quota) |
| `deployer_object_id` | `null` | Entra object ID for data-plane RBAC (defaults to the Terraform identity) |
| `enable_data_plane` | `true` | Run the sample-data + CU analyzer scripts during `apply` |

## Troubleshooting

| Symptom | Meaning | What to do |
| --- | --- | --- |
| `409 RequestConflict` on project or model deployment | Another `Microsoft.CognitiveServices/accounts/*` child write is already in flight on the same Foundry account | Wait for the other write to finish, avoid concurrent portal/Azure CLI/other pipeline changes, then rerun. Terraform's explicit chain only serializes the resources in **this apply** |
| `InsufficientQuota` on `gpt-image-2` | The region does not have enough incremental image quota | Re-run with `-var enable_image_generation=false` for a 3-model backup, or obtain more `eastus2` image quota before class |

## Models

Pinned versions were checked against the official lifecycle on **2026-08-26**
(`version_upgrade_option = "NoAutoUpgrade"` holds the pin). **Re-check the
[retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
before each delivery.**

> `model_profile=current` (default) deploys **gpt-5.4-mini** (`2026-03-17`) for broader quota
> headroom. `model_profile=parity` deploys **gpt-5-mini** (`2025-08-07`) to mirror the upstream lab.
> CU remains on **gpt-5.2** and **text-embedding-3-large**. The **gpt-4.1 family is Legacy** and
> retires **2027-04-14**; this stack does **not** deploy it.

| Model / profile | Deployment | Version | Status (2026-08-26) | Used by |
| --- | --- | --- | --- | --- |
| gpt chat (`current`) | `gpt-5.4-mini` | 2026-03-17 | GA, retires 2027-09-21 | Chat, agents, text, vision analysis (M1/M2/M3/M5) |
| gpt chat (`parity`) | `gpt-5-mini` | 2025-08-07 | GA, retires 2027-02-09; use only when matching the upstream lab profile | Chat, agents, text, vision analysis (M1/M2/M3/M5) |
| gpt-5.2 | `gpt-5.2` | 2025-12-11 | GA, retires 2027-06-08 | Content Understanding completion (M6) |
| text-embedding-3-large | `text-embedding-3-large` | 1 | GA, retires 2028-02-09 | Content Understanding embeddings (M6) |
| gpt-image-2 | `gpt-image-2` | 2026-04-21 | GA | Image generation (M5) — toggle `enable_image_generation` (default on) |

## Notes

- Terraform explicitly chains the Foundry account child writes
  (`Microsoft.CognitiveServices/accounts/*`, including the project and model deployments) within a
  single apply because the control plane accepts only one in-flight child operation per account.
  This ordering does **not** coordinate external portal / Azure CLI / other pipeline writes.
- Provider locks only coordinate **process-local** activity. `Microsoft.Authorization/roleAssignments`
  can stay parallel because they are not `Microsoft.CognitiveServices/accounts/*` child writes.
- Naming uses a fixed `local.random_str = "fnd"`. After a destroy/recreate within ~48h you may hit the
  Cognitive account soft-delete name reservation; switch `random_str` to `random_string.rid.result`
  (one-line edit in `MAIN.tf`) for a fresh suffix.
- `.terraform/`, `*.tfstate*`, and `.terraform.lock.hcl` are git-ignored.
