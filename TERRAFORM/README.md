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
| `azurerm_cognitive_deployment.gpt` = **gpt-4.1-mini** | Chat / agents / text / vision (M1, M2, M3, M5) |
| `azurerm_cognitive_deployment.cu_completion` = **gpt-4.1** | Content Understanding completion model (M6) |
| `azurerm_cognitive_deployment.embedding` = **text-embedding-3-large** | Content Understanding embeddings (M6) |
| `azurerm_cognitive_deployment.image` = **gpt-image-2** *(toggle)* | Image generation (M5) — GA; gated by `enable_image_generation` |
| `azurerm_storage_account.default` + containers | Sample receipts (M6) and images (M5) |
| Content Understanding analyzer `ai901receiptanalyzer` | Custom receipt field-extraction demo (M6) |

Speech (M4), Language (M3), and Vision image **analysis** (M5) need **no extra resources** — they're
exposed by the same multi-service Foundry account and demoed live in the portal/playground. Image
**generation** (M5) is deployed (`gpt-image-2`, GA); **video** generation (Sora, Preview) is a manual
portal step.

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
- `az login` to a subscription **with model quota** for `gpt-4.1-mini`, `gpt-4.1`, and
  `text-embedding-3-large` in **`eastus2`**.
- The signed-in principal must be able to create role assignments (Owner / User Access Administrator)
  on the new resource group.

> If `az` runs under a different identity than Terraform (e.g. a service principal), set
> `-var deployer_object_id=<the az login object id>` so the data-plane RBAC targets the right principal.

## Deploy

```powershell
cd TERRAFORM
az login                      # AAD session for the data-plane scripts
terraform init
terraform plan  -var group_postfix=0609     # confirm names like AI901-0609
terraform apply -var group_postfix=0609
```

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

In the [Foundry portal](https://ai.azure.com): the project shows the three deployments, and Content
Understanding lists the `ai901receiptanalyzer` analyzer — run it against a file in the
`sample-documents` container to see extracted receipt fields.

## Destroy

```powershell
terraform destroy -var group_postfix=0609
```

## Variables

| Variable | Default | Notes |
| --- | --- | --- |
| `group_postfix` | _(required)_ | 1–10 lowercase alphanumerics; drives all resource names |
| `chat_capacity` | `30` | gpt-4.1-mini TPM (thousands) |
| `cu_completion_capacity` | `10` | gpt-4.1 TPM for Content Understanding |
| `embedding_capacity` | `30` | text-embedding-3-large TPM |
| `enable_image_generation` | `true` | Deploy the gpt-image-2 image model (M5). Disable if no image quota in the region |
| `image_model_name` | `gpt-image-2` | Image-generation model (GA) |
| `image_model_version` | `2026-04-21` | Version for `image_model_name` |
| `image_capacity` | `1` | Image deployment capacity (image models share a small per-region quota) |
| `deployer_object_id` | `null` | Entra object ID for data-plane RBAC (defaults to the Terraform identity) |
| `enable_data_plane` | `true` | Run the sample-data + CU analyzer scripts during `apply` |

## Models

Pinned versions were **GA** as of 2026-06-09. **Re-check the
[retirement schedule](https://learn.microsoft.com/azure/ai-foundry/concepts/model-lifecycle-retirement)
before each delivery.**

| Model | Deployment | Version | Status (2026-06-09) | Used by |
| --- | --- | --- | --- | --- |
| gpt-4.1-mini | `gpt-4.1-mini` | 2025-04-14 | GA, retires 2027-10-14 | Chat, agents, text, vision analysis (M1/M2/M3/M5) |
| gpt-4.1 | `gpt-4.1` | 2025-04-14 | GA, retires 2027-10-14 | Content Understanding completion (M6) |
| text-embedding-3-large | `text-embedding-3-large` | 1 | GA | Content Understanding embeddings (M6) |
| gpt-image-2 | `gpt-image-2` | 2026-04-21 | GA | Image generation (M5) — toggle `enable_image_generation` |

> **Video generation (M5)** — `sora` / `sora-2` are **Preview** (deploy in `eastus2`). They are **not**
> deployed by this stack; deploy Sora manually in the Foundry portal if you want to demo video
> generation live. (`gpt-image-1`-series image models need access registration; this stack uses the
> GA `gpt-image-2` instead.)

## Notes

- Model deployments are **chained with `depends_on`** — the Cognitive Services control plane rejects
  parallel deployment writes.
- Naming uses a fixed `local.random_str = "fnd"`. After a destroy/recreate within ~48h you may hit the
  Cognitive account soft-delete name reservation; switch `random_str` to `random_string.rid.result`
  (one-line edit in `MAIN.tf`) for a fresh suffix.
- `.terraform/`, `*.tfstate*`, and `.terraform.lock.hcl` are git-ignored.
