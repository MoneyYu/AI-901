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
| 模型部署 `gpt-5.4-mini`（`model_profile=current`）或 `gpt-5-mini`（`model_profile=parity`） | M1、M2（agents）、M3（general-purpose 文字）、M5（多模態視覺） |
| 模型部署 `gpt-5.2` | M6 Content Understanding 完成模型 |
| 模型部署 `text-embedding-3-large` | M6 Content Understanding 嵌入 |
| 模型部署 `gpt-image-2`（toggle） | M5 影像生成（GA；`enable_image_generation` 可關閉） |
| Storage（`sample-documents`、`sample-images`） | M6 收據、M5 影像 |
| Content Understanding analyzer `ai901receiptanalyzer` | M6 收據欄位擷取 demo |

> Speech（M4）、Language（M3）、Vision 影像**分析**（M5）**不需額外資源**——由同一個多服務 Foundry 帳戶提供，於 portal/playground 現場示範。影像**生成**（M5）已預設部署 `gpt-image-2`；影片生成目前**不納入**備援 Terraform，課堂上只能保留概念說明，除非未來有可固定版本的 GA 替代方案。

## 模型設定檔（`model_profile`）

| Profile | 用途 | 說明 |
| --- | --- | --- |
| `current`（預設） | 講師備援環境 | `gpt-5.4-mini` / `2026-03-17`，與其餘 GA 模型一起部署；優先選擇退役較遠、配額較穩定的組合 |
| `parity` | 與上游 mslearn lab 對齊 | `gpt-5-mini` / `2025-08-07`（GA，2027-02-09 退役）；只有在你要和官方 lab 完全一致時才使用，並且要用相同 profile 跑 preflight 與 Terraform |

## 模型表（lifecycle-safe）

以下生命週期狀態已於 **2026-08-26** 重新核對（`version_upgrade_option = "NoAutoUpgrade"` 鎖版）。**每次開課前**請依
[retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)重新檢查。

> ⚠️ **gpt-4.1 家族現在是 Legacy**，官方退役日為 **2027-04-14**；本 stack **不再部署**它。預設備援 profile 使用 **gpt-5.4-mini**，若要和上游 lab 完全一致才切到 `parity` 的 **gpt-5-mini**。CU 仍固定使用 **gpt-5.2** + **text-embedding-3-large**，影像生成則固定是 **gpt-image-2**。

| 模型 / profile | 部署名稱 | 版本 | 狀態（2026-08-26） | 用途 | 部署方式 |
| --- | --- | --- | --- | --- | --- |
| `current` chat profile | `gpt-5.4-mini` | 2026-03-17 | GA，2027-09-21 退役 | chat / agents / text / vision（M1/M2/M3/M5） | Terraform |
| `parity` chat profile | `gpt-5-mini` | 2025-08-07 | GA，2027-02-09 退役；僅在需要完全比照上游 lab 時使用 | chat / agents / text / vision（M1/M2/M3/M5） | Terraform |
| gpt-5.2 | `gpt-5.2` | 2025-12-11 | GA，2027-06-08 退役 | Content Understanding 完成模型（M6） | Terraform |
| text-embedding-3-large | `text-embedding-3-large` | 1 | GA，2028-02-09 退役 | Content Understanding 嵌入（M6） | Terraform |
| gpt-image-2 | `gpt-image-2` | 2026-04-21 | GA | M5 影像生成 | Terraform（toggle `enable_image_generation`，預設 on） |

> **M5 影像 / 影片生成策略**：`gpt-image-2` 已由 Terraform 預設部署，因此備援環境預期是 **4 個模型部署**（chat + CU completion + embedding + image）；若關閉 `enable_image_generation` 則剩 3 個。影片生成備援已移除：`sora-2` 屬 Preview、catalog target retirement 為 2026-09-15，且目前沒有可固定版本的 GA 影片生成替代方案，所以不要承諾「可回退到 Terraform 或課前手動部署影片模型」。

## Entra ID（AAD）only — 不使用任何 key

公司資安政策禁止 account/access key，整套環境皆為 key-less：

- **Storage**：`shared_access_key_enabled = false`、provider `storage_use_azuread = true`、容器以管理平面建立、上傳腳本用 `az ... --auth-mode login`。
- **Foundry（AI Services）**：`local_auth_enabled = false` + `custom_subdomain_name`（regional endpoint 不接受 Entra ID token，故必須設定 custom subdomain）。
- 資料平面以 `az account get-access-token`（AAD bearer token）呼叫，並對 **401/403 重試**以吸收 RBAC 傳播延遲；deployer 取得 **Storage Blob Data Contributor** 與 **Cognitive Services User** 角色。

## 區域與配額

- 區域：**`eastus2`**（local，非自由變數）。請先確認該區對所選 chat profile、`gpt-5.2`、`text-embedding-3-large`，以及預設開啟時的 `gpt-image-2` 有配額。
- 容量變數預設較保守（chat 30 / cu 10 / embedding 30，單位千 TPM），可依配額調整。

## 端到端測試紀錄（每次驗證後補上）

| 日期 | group_postfix | 結果 | 資源數 | 備註 |
| --- | --- | --- | --- | --- |
| 2026-06-09 | 0609 | ✅ apply → 資料平面 → destroy 全程通過 | 15 | 訂用帳戶 `ME-MngEnvMCAP124981-tzyu-1`（eastus2）。資料平面：3 收據 + 3 影像上傳、`ai901receiptanalyzer` 建立成功。CU analyzer 首次因模型部署傳播延遲（400 DeploymentIdNotFound）失敗，已於腳本加入該情況重試後通過。 |
| 2026-06-10 | 0610 | ✅ apply → 資料平面 → destroy 全程通過 | 16 | 新增 `gpt-image-2`（GA）影像生成部署並驗證成功（4 個模型部署）。CU defaults PATCH 同樣加入 DeploymentIdNotFound 重試後通過。 |
| 2026-06-10 | verify | ✅ **單次 apply 從零部署成功**（無需重跑）→ destroy | 16 | 乾淨驗證：硬化後的 CU 重試在**單一 apply 內**吸收部署傳播延遲，analyzer 一次成功；4 模型部署 + 樣本資料上傳皆完成；destroy 乾淨。 |
| 2026-06-10 | vid2 | ⚠️ video toggle 測試：config 有效但配額不足 | — | `enable_video_generation=true` 測試 `sora-2`：部署請求**有效並被接受**，但回傳 `InsufficientQuota`（Sora-2 RPM 15/15 已用滿）。證實 `sora-2` 可由 Terraform 部署、但本訂用帳戶無 Sora 配額，故 `enable_video_generation` **預設 off**。當天 eastus2 控制平面異常緩慢（部署逐一耗時數分鐘、出現 token 過期與 connection reset），已清乾淨。 |
| 2026-07-20 | 0720 | ✅ **模型遷移驗證通過**（apply 成功） | 16 | gpt-4.1 家族棄用（2026-10-14 退役）＋ gpt-4.1 GlobalStandard 配額凍結（3075/3075）→ 遷移 chat `gpt-4.1-mini`→`gpt-5.4-mini`、CU 完成模型 `gpt-4.1`→`gpt-5.2`（embedding 不變）。`terraform apply -var group_postfix=0720`：**5 added / 1 destroyed**；CU defaults 驗證通過、`ai901receiptanalyzer` 建立 succeeded；實際 `analyzeBinary` 收據推論回傳萃取欄位 + gpt-5.2 生成摘要。環境保留（未 destroy）。 |
| 2026-08-26 | docs | ✅ 文件 / 指引同步（未執行 Azure apply 或 destroy） | — | 依官方生命週期更新 trainer-only 文件：`current`=`gpt-5.4-mini/2026-03-17`、`parity`=`gpt-5-mini/2025-08-07`、CU=`gpt-5.2/2025-12-11`、embedding=`text-embedding-3-large/1`、image=`gpt-image-2/2026-04-21`。移除 Sora / video 備援承諾，但保留 2026-06-10 的 15/15 歷史觀察供追溯。 |
| 2026-08-26 | 0826fix | ✅ **fresh apply → CU/image smoke tests → destroy** | 16 | `Test-ModelAvailability.ps1`（`current`）通過；`apply` 建立 16 個資源、0 個 409，序列為 Foundry account → project → gpt-5.4-mini → gpt-5.2 → embedding → gpt-image-2。上傳 3 份收據 + 3 張影像、analyzer 建立 succeeded；Entra ID 收據推論回傳 `ReceiptDate`、`Summary`、`Items`、`Total`、`SubTotal`、`MerchantName`、`Tax`，gpt-image-2 產生 1 張影像（HTTP 200）。`destroy` 移除 16 個資源、0 個 409/412，先依反向順序刪除 deployments，再刪 project、account、resource group。 |

## 參考

- Terraform 操作：[`../TERRAFORM/README.md`](../TERRAFORM/README.md)
- 備課指南：[`./teaching-guide.md`](./teaching-guide.md)
- 模型退役排程：[Model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
- Content Understanding 模型部署：[Model deployment options](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/models-deployments)
