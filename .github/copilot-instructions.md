# Copilot instructions — AI-901 course reference repo

This repo is the **reference repo for the Microsoft course AI-901: Introduction to AI in Azure**
(the refreshed *Azure AI Fundamentals*, replacing AI-900). It is prepared with the
`.github/skills/course-prep` skill. It is **not** an application codebase — there is no app build or
test suite. Deliverables are an attendee README, a trainer-only demo Terraform stack, and trainer docs.

## Layout

- `README.md` — **attendee-facing** HackMD-style course reference (front-matter, `:::success/info/warning`
  admonitions, a `## Mind Map` ```` ```markmap ```` block). Keep trainer/demo detail OUT of it.
- `TERRAFORM/` — trainer-only **backup/fallback** demo stack (`MAIN.tf` providers/vars/locals/RGs,
  `MOD.tf` resources + data-plane, `OUTPUT.tf`, `scripts/*.ps1`, `sample-data/`).
- `docs/` — trainer-only (`teaching-guide.md` 備課指南 in 正體中文, `demo-environment.md`).
- `PPT/` — copyrighted slide decks; **git-ignored**, never committed. Extract talking points into `docs/`.
- `DEMO/` — small in-class demo assets.

> Reference sibling repos for shape: `MoneyYu/AI-3008`, `AI-3016`, `AI-102`. The Terraform mirrors
> **AI-3008** (the canonical pattern).

## Hard rules

1. **Attendee README vs trainer `docs/`** — never put demo-environment, model rationale, Terraform, or
   Skillable internals in `README.md`; those live in `docs/`. Keep per-instance metadata current
   (Date, Course ID, survey, Skillable key).
2. **Entra ID (AAD) only — no account/access keys.** Storage `shared_access_key_enabled = false` +
   provider `storage_use_azuread = true`; Cognitive/AI Services `local_auth_enabled = false` **and**
   a `custom_subdomain_name` (regional endpoints reject AAD tokens). Use managed identity + RBAC role
   assignments; scripts use `az account get-access-token` / `--auth-mode login` and **retry on 401/403**.
3. **Models must be GA and not near retirement.** Re-check the
   [retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
   with today's date before every delivery. Current profiles: `model_profile=current` =>
   **gpt-5.4-mini** (`2026-03-17`, GA retires **2027-09-21**); `model_profile=parity` =>
   **gpt-5-mini** (`2025-08-07`, GA retires **2027-02-09**) to mirror the upstream lab. Content Understanding stays on
   **gpt-5.2** (`2025-12-11`, GA retires **2027-06-08**) + **text-embedding-3-large** (`1`, GA retires
   **2028-02-09**); image generation is **gpt-image-2** (`2026-04-21`, default-on toggle). ⚠️ The
   **gpt-4.1 family is Legacy (retires 2027-04-14)** and is not deployed. Do not promise a Terraform
   video-generation backup unless a current GA replacement exists.
4. **Verify every external link (HTTP 200) before adding it** to README/docs.
5. **The Terraform is a *backup* that must reach a completed (resources + data-plane) state** so demos
   show real results immediately.
6. **Python work uses a venv.** Commit only generated binary sample-data, not the generator.

## Terraform conventions (mirror AI-3008)

- `azurerm ~>4.20` (modern Foundry surface: `azurerm_cognitive_account.project_management_enabled` +
  `azurerm_cognitive_account_project`).
- One `var.group_postfix` (validated `^[a-z0-9]{1,10}$`) drives all names via `locals`
  (`group_name = "AI901-<postfix>"`, `class_name = "ai901"`, fixed `random_str = "fnd"`).
- Region is a **local** (`eastus2`), not a free variable.
- Apply `local.default_tags` (`environment` + `SecurityControl = "Ignore"`) to every taggable resource.
- **Serialize all `Microsoft.CognitiveServices/accounts/*` child writes with explicit `depends_on`** —
  project creation, model deployments, and any same-account cleanup-marker operations must run
  one-at-a-time because the control plane accepts only one child operation per account. Through
  `azurerm` v4.81, `azurerm_cognitive_account_project` was not covered by the provider's deployment lock,
  and provider locks only coordinate process-local activity. `Microsoft.Authorization/roleAssignments`
  can stay parallel. Deployment name == model name (keeps the CU default mapping an identity map).
- Data plane = `terraform_data` + `local-exec` (`pwsh -NoProfile -File scripts/*.ps1`), gated by
  `var.enable_data_plane`. **Each `environment` map var must match the script's `Get-RequiredEnv` calls.**
- Don't commit `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl`.

## Validate

```powershell
cd TERRAFORM
terraform fmt -recursive
terraform init -backend=false
terraform validate
# PowerShell scripts (no test runner): AST-parse each
Get-ChildItem scripts/*.ps1 | ForEach-Object {
  $e=$null; [System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$null,[ref]$e)
  if ($e.Count) { "FAIL: $($_.Name)"; $e } else { "OK: $($_.Name)" }
}
```

The real proof is a `terraform apply` → `destroy` against Azure (needs `az login`, subscription, and
model quota in `eastus2`); it cannot run in CI. Record the e2e result in the tracking issue.

## Binary assets

`.gitattributes` marks `*.pdf *.png *.jpg *.pptx *.zip` as `binary` so the global `* text=auto` can't
corrupt them. Generate `sample-data/` binaries one-time with a Python venv; commit only the binaries.

## Git/GitHub

Conventional Commits + always append
`Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`. Use a GitHub **Task** issue
(body = scope, comments = progress) created via `gh api`.
