# AI-901 示範環境（Demo Environment）

> 講師專用（trainer-only）。說明 AI-901 的**備援示範環境**與**模型選擇**。
> 完整部署步驟與變數見 [`../TERRAFORM/README.md`](../TERRAFORM/README.md)。

## 目的

上課時講師會在 [Microsoft Foundry](https://ai.azure.com) **現場從零建立**所有資源；本環境是**備援（backup）**：
若現場建置失敗，可用這套 Terraform 把環境快速還原到**已完成、可立即示範**的狀態（資源 + 資料平面），
讓每個模組的 demo 立刻看到真實結果。

## 架構（精簡版 Foundry stack）

單一 **Microsoft Foundry**（`kind = AIServices`，啟用 project）帳戶 + 專案即可承載本課所有服務：
Azure OpenAI、Azure AI Language、Speech、Vision、Content Understanding。

| 資源 | 對應模組 |
| --- | --- |
| Foundry 帳戶（AIServices）+ 專案 | M1（也提供 M3 Language / M4 Speech / M5 Vision / M6 CU 的端點） |
| 模型部署 `gpt-4.1-mini` | M1、M2（agents）、M3（general-purpose 文字）、M5（多模態視覺） |
| 模型部署 `gpt-4.1` | M6 Content Understanding 完成模型 |
| 模型部署 `text-embedding-3-large` | M6 Content Understanding 嵌入 |
| 模型部署 `gpt-image-2`（toggle） | M5 影像生成（GA；`enable_image_generation` 可關閉） |
| Storage（`sample-documents`、`sample-images`） | M6 收據、M5 影像 |
| Content Understanding analyzer `ai901receiptanalyzer` | M6 收據欄位擷取 demo |

> Speech（M4）、Language（M3）、Vision 影像**分析**（M5）**不需額外資源**——由同一個多服務 Foundry 帳戶提供，於 portal/playground 現場示範。影像**生成**（M5）已部署 `gpt-image-2`；**影片**生成（Sora，Preview）仍為手動。

## 模型表（lifecycle-safe）

版本為 **2026-06-09** 當下的 **GA**。**每次開課前**請依
[retirement schedule](https://learn.microsoft.com/azure/ai-foundry/concepts/model-lifecycle-retirement)重新檢查。

| 模型 | 部署名稱 | 版本 | 狀態（2026-06-09） | 用途 | 部署方式 |
| --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | `gpt-4.1-mini` | 2025-04-14 | GA，2027-10-14 退役 | chat / agents / text / vision（M1/M2/M3/M5） | Terraform |
| gpt-4.1 | `gpt-4.1` | 2025-04-14 | GA，2027-10-14 退役 | Content Understanding 完成模型（M6） | Terraform |
| text-embedding-3-large | `text-embedding-3-large` | 1 | GA | Content Understanding 嵌入（M6） | Terraform |
| gpt-image-2 | `gpt-image-2` | 2026-04-21 | GA | M5 影像生成 | Terraform（toggle `enable_image_generation`） |
| sora / sora-2（影片生成） | — | — | Preview | M5 影片生成（選用） | **手動於 Foundry 入口** |

> **影像 vs 影片生成（M5）**：`gpt-image-2` 為 **GA**，已由 Terraform 部署（`enable_image_generation` 預設 true，配額不足時可關閉）。`gpt-image-1` 系列需申請存取權限，故改用 GA 的 `gpt-image-2`。**影片**生成（`sora`/`sora-2`）仍為 **Preview**，請在 Foundry 入口手動部署。CU 的完成模型僅支援固定集合（gpt-4.1 / gpt-4.1-mini / gpt-5.2），故與 chat 模型分開部署。

## Entra ID（AAD）only — 不使用任何 key

公司資安政策禁止 account/access key，整套環境皆為 key-less：

- **Storage**：`shared_access_key_enabled = false`、provider `storage_use_azuread = true`、容器以管理平面建立、上傳腳本用 `az ... --auth-mode login`。
- **Foundry（AI Services）**：`local_auth_enabled = false` + `custom_subdomain_name`（regional endpoint 不接受 Entra ID token，故必須設定 custom subdomain）。
- 資料平面以 `az account get-access-token`（AAD bearer token）呼叫，並對 **401/403 重試**以吸收 RBAC 傳播延遲；deployer 取得 **Storage Blob Data Contributor** 與 **Cognitive Services User** 角色。

## 區域與配額

- 區域：**`eastus2`**（local，非自由變數）。請先確認該區對三個模型有配額。
- 容量變數預設較保守（chat 30 / cu 10 / embedding 30，單位千 TPM），可依配額調整。

## 端到端測試紀錄（每次驗證後補上）

| 日期 | group_postfix | 結果 | 資源數 | 備註 |
| --- | --- | --- | --- | --- |
| 2026-06-09 | 0609 | ✅ apply → 資料平面 → destroy 全程通過 | 15 | 訂用帳戶 `ME-MngEnvMCAP124981-tzyu-1`（eastus2）。資料平面：3 收據 + 3 影像上傳、`ai901receiptanalyzer` 建立成功。CU analyzer 首次因模型部署傳播延遲（400 DeploymentIdNotFound）失敗，已於腳本加入該情況重試後通過。 |
| 2026-06-10 | 0610 | ✅ apply → 資料平面 → destroy 全程通過 | 16 | 新增 `gpt-image-2`（GA）影像生成部署並驗證成功（4 個模型部署）。CU defaults PATCH 同樣加入 DeploymentIdNotFound 重試後通過。 |
| 2026-06-10 | verify | ✅ **單次 apply 從零部署成功**（無需重跑）→ destroy | 16 | 乾淨驗證：硬化後的 CU 重試在**單一 apply 內**吸收部署傳播延遲，analyzer 一次成功；4 模型部署 + 樣本資料上傳皆完成；destroy 乾淨。 |

## 參考

- Terraform 操作：[`../TERRAFORM/README.md`](../TERRAFORM/README.md)
- 備課指南：[`./teaching-guide.md`](./teaching-guide.md)
- 模型退役排程：[Model lifecycle and retirement](https://learn.microsoft.com/azure/ai-foundry/concepts/model-lifecycle-retirement)
- Content Understanding 模型部署：[Model deployment options](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/models-deployments)
