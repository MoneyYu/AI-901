# AI-901 備課指南（Trainer Teaching Guide）

> 講師專用（trainer-only）。本文件**不對學員公開**，請勿併入學員版 `README.md`。
> 內容彙整自 AI-901 官方投影片講者備註（speaker notes）、官方 Learn 模組與 lab。

---

## 1. 課程概覽

| 項目 | 說明 |
| --- | --- |
| 課程 | **AI-901T00-A: Introduction to AI in Azure** |
| 認證 | Microsoft Certified: **Azure AI Fundamentals**（exam **AI-901**，beta） |
| 等級 / 長度 | Beginner，**1 天**（ILT） |
| 對象 | AI 開發初學者；具備基本 Python 與雲端概念（儲存、計算、驗證）者尤佳，但**非必要** |
| 認證型態 | 只有 **Achievement Code**（成就碼），**沒有** Applied Skills credential |

:::warning
**AI-901 是用來取代 AI-900 的改版課程（refresh）。請勿沿用舊的 AI-900 教材。** 主要差異：
- **移除**獨立的「Machine Learning」模組；**Generative AI + Agents 提前到模組 2**。
- 原「NLP」模組**拆成**「Text analysis（模組 3）」與「Speech（模組 4）」兩個模組。
- 全面改用 **Microsoft Foundry** 品牌（取代 Azure AI Foundry），並以 **agent + SDK** 為主軸。
- 文字分析改教**兩種方法**（general-purpose 模型 + Azure Language）；視覺新增**影像／影片生成**；
  資訊擷取以 **Content Understanding** 為核心（含音訊／影片）。
- 示範模型由 gpt-4o / dall-e-3 改為 **gpt-5 系列聊天模型**（官方實驗部署 gpt-5-mini；備援 Terraform 用 gpt-5.4-mini）。Lab 僅有 **英文（與 ja-jp）**，無 zh 版本。
:::

---

## 2. 課程地圖：6 個模組

| # | 模組（Module） | 對應 Lab（mslearn-ai-fundamentals） |
| --- | --- | --- |
| 1 | Get started with AI in Azure | [Get started with Microsoft Foundry](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/00-explore-foundry.html) |
| 2 | Get started with generative AI and agents | [generative AI and agents](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/02a-generative-ai.html) |
| 3 | Get started with text analysis | [text analysis](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/03b-text-analysis.html) |
| 4 | Get started with speech | [speech](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/04a-speech.html) |
| 5 | Get started with computer vision | [computer vision](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/05a-image-analysis.html) |
| 6 | Get started with information extraction | [Content Understanding](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/06a-content-understanding.html) |
| 加碼 | Foundry IQ（選用） | [Foundry IQ](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/07-foundry-iq.html) |

> Lab 採「**雙軌**」設計：**概念 lab**（不需 Azure 訂用帳戶，瀏覽器即可）＋**實作 lab**（需訂用帳戶，在
> Microsoft Foundry 操作）。每個模組投影片都附 `aka.ms/mslearn-*` 對應的官方 Learn 模組連結。

---

## 3. 建議議程與時間分配（1 天，約 6.5 小時教學）

| 時間 | 內容 |
| --- | --- |
| 09:00–09:20 | 課程介紹、環境/Skillable 登入、Foundry 專案前置 |
| 09:20–10:10 | **M1** Get started with AI（含 Foundry lab） |
| 10:10–11:10 | **M2** Generative AI & agents（含 agent lab） |
| 11:10–11:20 | 休息 |
| 11:20–12:15 | **M3** Text analysis |
| 12:15–13:15 | 午餐 |
| 13:15–14:00 | **M4** Speech |
| 14:00–14:55 | **M5** Computer vision |
| 14:55–15:05 | 休息 |
| 15:05–16:00 | **M6** Information extraction（Content Understanding） |
| 16:00–16:30 | 總結、認證/考試說明、Q&A |

> 時間吃緊時，每個模組的 **Optional Exercise（概念 lab）** 可略過或當作回家作業；保留各模組的**實作 lab**。

---

## 4. 貫穿全課的核心觀念（開場點出、全程反覆強調）

1. **AI 工作負載全景圖**：Generative AI & Agents、Text/Language、Speech、Computer Vision、
   Information Extraction —— 五大工作負載對應到後續五個模組（M2–M6），M1 是平台與概念。
2. **Microsoft Foundry 是統一平台**：Foundry **resource**（Azure 基礎設施）vs Foundry **project**
   （隔離的開發工作區）；專案中操作 **Models / Agents / Tools / Knowledge** 四大元素。
   每個實作 lab 都要先建立 Foundry 專案——提前讓學員有心理準備。
3. **關鍵比較（投影片的精華，務必畫成對照表講解）**：
   - **API key vs Microsoft Entra ID token**：key 是共用密鑰；Entra ID 是身分式、可用 RBAC、無長期密鑰外洩風險。
   - **ChatCompletions vs Responses API**：Chat Completions 為 stateless（每回合送完整對話）；
     **Responses** 為較新的 stateful、且 **agent-aware**（課程程式皆用 `responses.create`）。
   - **LLM vs SLM**：能力/廣度 vs 輕量/低延遲（裝置端）。
   - **General-purpose 模型 vs Azure Language in Foundry Tools**（M3 重點，見下表）。
   - **OpenAI Python SDK vs Azure Language SDK**：自然語言彈性 vs 結構化＋信賴分數。
4. **模型生命週期（model lifecycle）**：每次開課前都要重新檢查
   [retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)。
   ⚠️ **gpt-4.1 家族已棄用（2026-10-14 退役）**，示範已改用 **gpt-5.4-mini**（chat，GA 至 2027-03-18）與
   **gpt-5.2**（CU 完成模型，GA，但 **2026-12-12 退役**——12 月前需再遷移一次）。
5. **示範環境是 Entra ID（AAD）only、不使用任何 key**：備援 Terraform 環境全程以受控識別 + RBAC 驗證
   （見 [`docs/demo-environment.md`](./demo-environment.md)）。這也呼應 M1「key vs Entra ID」的觀念。

### M3 對照表：兩種文字分析方法

| 用 **general-purpose 模型**（如 gpt-5.4-mini）時… | 用 **Azure Language in Foundry Tools** 時… |
| --- | --- |
| 需要彈性、對話式分析 | 需要一致、**結構化**輸出 |
| 想在一個 prompt 內合併多個任務 | 建立自動化 pipeline |
| 自然語言回應即可 | 需要明確的**信賴分數（confidence）** |
| 可容忍部分變異 | 處理**受規範資料**（PII/PHI）、需可重現的 production 結果 |

> 背景：許多「Azure Language in Foundry」功能正在退役，因此課程改教「兩種方法併用」。

---

## 5. 逐模組備課指南

### 模組 1 — Get started with AI in Azure
- **學習目標**：理解 AI 是什麼、五大 AI 工作負載、負責任 AI 六原則；認識 Azure 階層與 Microsoft Foundry、endpoint。
- **講解重點**：AI = 模仿人類能力的軟體（非「人類智慧」）；負責任 AI 六原則
  （Fairness、Reliability & Safety、Privacy & Security、Inclusiveness、Transparency、Accountability）；
  Azure 階層 **Tenant → Subscription → Resource group → Resources**，身分由 **Entra ID** 管理；
  Foundry resource vs project；endpoint = HTTP 位址，以 key 或 Entra ID token 驗證，SDK 封裝 REST。
- **Demo / Lab**：[Get started with Microsoft Foundry](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/00-explore-foundry.html)（建立專案、部署 `gpt-5-mini`、連 chat app）。
- **常見問題 / 坑**：學員常分不清 resource 與 project；強調「每個 lab 都要先建專案」。
  **Knowledge check 解答**：① 生成式 AI＝以語言模型「依 prompt 產生原創內容」；② AI agent＝「能代表使用者執行任務的 AI 應用」；
  ③ Foundry 建構在 Azure 之上、使用 Azure 資源；④ **endpoint 是呼叫模型的 URL，key 用來驗證請求**。
- **重要連結**：[What is Microsoft Foundry?](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry)、
  [Responsible AI](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)、
  [Foundry endpoints](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/endpoints)。

### 模組 2 — Get started with generative AI and agents
- **學習目標**：理解生成式 AI、語言模型運作（tokens/embeddings/attention/transformer）、agent 的組成。
- **講解重點**：生成式 AI＝產生新內容（文字/影像/程式碼）；**LLM vs SLM**；
  以「手機預測字」類比「逐 token 預測」；**agent = 模型 + 指示(instructions) + 工具(tools) + 知識(knowledge)**，
  能自主行動並協作；Foundry 模型目錄（第一方 Azure OpenAI vs 夥伴/社群）、部署考量（deployment type/版本/速率/guardrails）；
  **playground → 用 Responses API 寫程式 → Foundry Agent Service 建 agent**。
- **Demo / Lab**：[generative AI and agents](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/02a-generative-ai.html)（playground 試 system prompt/參數、建立帶 file search 工具的 agent）。
- **常見問題 / 坑**：學員會問「模型 vs agent 差別」——強調 agent 多了指示、工具、行動與自主性。
  **Knowledge check 解答**：① LLM＝「產生擬人文字的模型」；② embeddings＝「捕捉語意的 token 向量表示」；
  ③ attention＝「檢視每個 token 與周圍 token 的關係」；④ 模型目錄＝「跨供應商探索/比較生成式模型的中樞」；
  ⑤ playground 價值＝「測 prompt、比較模型、擷取可重用設定」；⑥ 送 prompt 給 agent 的程式行＝ `responses.create(...)` 那一行。
- **重要連結**：[Understand embeddings](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/understand-embeddings)、
  [Foundry Agent Service](https://learn.microsoft.com/azure/ai-foundry/agents/overview)、
  [Responses API](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/responses)。

### 模組 3 — Get started with text analysis
- **學習目標**：理解 NLP 任務，並能選用「general-purpose 模型」或「Azure Language」兩種方法。
- **講解重點**：常見 NLP 任務（key phrase、NER、sentiment & opinion mining、PII、language detection、summarization）；
  **兩種方法對照**（見第 4 節表）；**OpenAI Python SDK（Responses API）vs Azure Language SDK**
  （`recognize_entities` / `recognize_pii_entities` / `analyze_sentiment`，回傳類別＋信賴分數）；
  以 **MCP（Model Context Protocol）** 把 Azure Language 工具接進 agent。
- **Demo / Lab**：[text analysis](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/03b-text-analysis.html)。
- **常見問題 / 坑**：學員會問「何時用哪一種」——用對照表回答（結構化/信賴分數/受規範資料 → Azure Language）。
  **Knowledge check 解答**：① 需「確定性、結構化輸出」→ **Azure Language SDK**；
  ② client 物件＝「協助應用程式與 Azure Language 服務溝通」；③ Azure Language MCP server＝「透過 MCP 將 Language 能力開放給 agent」。
- **重要連結**：[What is Azure AI Language?](https://learn.microsoft.com/azure/ai-services/language-service/overview)、
  [NER](https://learn.microsoft.com/azure/ai-services/language-service/named-entity-recognition/overview)、
  [Sentiment](https://learn.microsoft.com/azure/ai-services/language-service/sentiment-opinion-mining/overview)、
  [PII](https://learn.microsoft.com/azure/ai-services/language-service/personally-identifiable-information/overview)、
  [MCP tool](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/model-context-protocol)。

### 模組 4 — Get started with speech
- **學習目標**：理解 speech-to-text（STT）與 text-to-speech（TTS）原理與實作，認識即時語音 agent（Voice Live）。
- **講解重點**：STT pipeline（擷取→前處理/特徵→聲學模型/phonemes→語言模型→後處理）；
  TTS pipeline（正規化→語言模型/phonemes→prosody→波形）；三種使用方式（**playground / Speech SDK / Foundry Tools MCP server**）；
  **Voice Live**＝即時、可中斷、抑制背景雜訊的對話式語音 agent。
- **Demo / Lab**：[speech](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/04a-speech.html)（Voice Live 服務）。
- **常見問題 / 坑**：概念 lab 用瀏覽器 WebSpeech，部分瀏覽器/CPU 不支援——若失敗，改用 Foundry playground 示範。
  **Knowledge check 解答**：① 前處理＝「從波形擷取特徵向量」；② phonemes＝「語音中最小的聲音單位」；
  ③ prosody＝「確保自然發音與語速」；④ 用 STT SDK 的原因＝「可把語音辨識直接加入應用程式碼」；
  ⑤ TTS SDK 處理＝「驗證、網路通訊與音訊產生」；⑥ Voice Live SDK＝「建立即時連線、串流音訊、處理回應與中斷」。
- **重要連結**：[What is the Speech service?](https://learn.microsoft.com/azure/ai-services/speech-service/overview)、
  [Speech to text](https://learn.microsoft.com/azure/ai-services/speech-service/speech-to-text)、
  [Text to speech](https://learn.microsoft.com/azure/ai-services/speech-service/text-to-speech)。

### 模組 5 — Get started with computer vision
- **學習目標**：理解視覺任務與模型（CNN / ViT / 多模態 / diffusion），並能用多模態模型分析與生成影像/影片。
- **講解重點**：四種任務（classification / object detection / semantic segmentation / contextual analysis）；
  **CNN（局部特徵）vs ViT（attention + patches，全域脈絡）**；多模態（視覺＋語言向量）；
  **diffusion 模型**（去噪生成）；以 **Responses API + 多模態模型**做 image-to-text；
  在 Foundry 模型目錄用「text to image」「video generation」任務搜尋（如 gpt-image、sora）。
- **Demo / Lab**：[computer vision](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/05a-image-analysis.html)（分析影像、生成影像、生成影片）。
- **常見問題 / 坑**：image/video 生成模型多為 **Preview / 配額有限**，備援 Terraform **未**自動部署——需要時請在 Foundry 入口手動部署（見 demo-environment）。
  **Knowledge check 解答**：① 影像分析的對象＝**Pixels**；② CNN filters＝「從影像擷取數值特徵」；
  ③ ViT＝「用 attention 處理影像 patch、產生脈絡 embedding」；④ multimodal＝「能處理一種以上資料型態（文字＋影像）」；
  ⑤ 程式化生成影像＝「用 **Responses API** 呼叫已部署的 image 模型」；⑥ Sora 採非同步＝「影片生成耗資源、需要時間」。
- **重要連結**：[What is Azure AI Vision?](https://learn.microsoft.com/azure/ai-services/computer-vision/overview)、
  [Vision-enabled chat models](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/gpt-with-vision)、
  [Image generation](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/dall-e)、
  [Video generation (Sora)](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/video-generation)。

### 模組 6 — Get started with information extraction
- **學習目標**：理解資訊擷取（OCR → 欄位擷取/對應），並用 Azure Content Understanding 從文件與音訊/影片擷取結構化資料。
- **講解重點**：資訊擷取＝把非結構化內容轉成結構化資料；**OCR 只給文字、不給語意**；
  欄位擷取/對應/正規化才產生可用欄位；**Azure Content Understanding in Foundry Tools** 是統一體驗——
  prebuilt 與 custom **analyzer**、REST API 回傳 JSON；不僅文件，也支援**音訊與影片**（通話分析、會議摘要等）。
- **Demo / Lab**：[Content Understanding](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/06a-content-understanding.html)。備援環境已預建 `ai901receiptanalyzer` 收據 analyzer，可直接對 `sample-documents` 內收據做擷取示範。
- **常見問題 / 坑**：CU 需先在資源層設定**預設模型部署**（gpt-5.2 完成模型 / text-embedding-3-large 嵌入）——備援 Terraform 已自動處理；手動建立時務必記得。
  **Knowledge check 解答**：① 資訊擷取＝「分析非結構化內容以擷取相關欄位與值」；② OCR＝「將文字影像轉成機器可讀文字」；
  ③ 生成式 AI 的助益＝「用語意模型把擷取值對應到欄位」；④ CU 優於純 OCR＝「理解文件結構並對應到 schema」；
  ⑤ analyzer 角色＝「定義內容如何處理與回傳哪些結構化資料」；⑥ CU SDK 送出後＝「需輪詢（poll）URL 直到工作完成」。
- **重要連結**：[What is Content Understanding?](https://learn.microsoft.com/azure/ai-services/content-understanding/overview)、
  [Analyzers](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/analyzer-reference)、
  [Document Intelligence (OCR)](https://learn.microsoft.com/azure/ai-services/document-intelligence/overview?view=doc-intel-4.0.0)。

---

## 6. 預期學員問題 Q&A

- **Q：AI-901 和 AI-900 差在哪？要不要重考？**
  A：AI-901 是 AI-900 的改版（取代）。內容更聚焦 Microsoft Foundry、生成式 AI 與 agents，並加入 SDK/實作深度。
- **Q：有沒有像 Applied Skills 那種認證？**
  A：**沒有**。本課只有 **Achievement Code（成就碼）**；認證走 exam **AI-901**（Azure AI Fundamentals，beta）。
- **Q：要會寫程式嗎？**
  A：不需深厚程式背景；具備基本 Python 語法概念會更輕鬆，但重點是「理解能力與流程」，不是從零訓練模型。
- **Q：Lab 有中文嗎？**
  A：**目前沒有**。Lab 僅英文（另有 ja-jp）；課程投影片與 learning path 有中文。
- **Q：一定要用 key 嗎？公司禁止用 access key。**
  A：可以全程用 **Entra ID（AAD）**。示範/備援環境即為 key-less 設計（受控識別 + RBAC）。
- **Q：ChatCompletions 還是 Responses API？**
  A：新應用與 agent 用 **Responses API**（stateful、agent-aware）；課程程式皆採 `responses.create`。

---

## 7. 課前準備清單（開課前 1–2 天）

- [ ] 重新檢查**模型生命週期**（gpt-5.4-mini / gpt-5.2 是否仍 GA、未近退役；⚠️ gpt-5.2 於 2026-12-12 退役）。
- [ ] 確認目標區域（`eastus2`）對 **gpt-5.4-mini / gpt-5.2 / text-embedding-3-large** 有**配額**。
- [ ] 如需示範 **image/video 生成（M5）**，先在 Foundry 入口**手動部署** gpt-image / sora（Preview/配額）。
- [ ] 部署備援環境並驗證：`terraform apply -var group_postfix=<MMDD>`，確認 3 個模型部署 + 收據 analyzer 完成
      （見 [`docs/demo-environment.md`](./demo-environment.md)）。下課後 `terraform destroy`。
- [ ] 取得並測試 **Skillable** 訓練金鑰；確認學員可登入 lab 環境。
- [ ] 客製投影片中的 lab 連結頁（hosted lab 環境）並移除「Trainers:」箭頭備註。
- [ ] 準備 `az login`（資料平面腳本需要 AAD 工作階段）。

---

## 8. 講師小技巧

- **每個實作 lab 先建立 Foundry 專案**：開課時先示範一次，之後各模組就快。
- **善用 playground**：先在 playground 講 prompt/參數/多模態，再帶到 Responses API 程式碼，降低「看不懂程式」焦慮。
- **時間救援**：略過各模組的 **Optional/概念 lab**（不需訂用帳戶，可當回家作業），保留實作 lab。
- **示範 vs 預建**：image/video 生成、Content Understanding analyzer 等耗時/受配額限制者，**用備援環境預建**好直接展示結果。
- **反覆回扣比較表**：key vs Entra ID、ChatCompletions vs Responses、general-purpose vs Azure Language——
  這些是考試與理解的重點，建議全程多次回扣。

---

## 參考

- 學員版參考頁：[`../README.md`](../README.md)
- 示範環境與模型表：[`./demo-environment.md`](./demo-environment.md)
- Learning path：[Get started with AI apps and agents](https://learn.microsoft.com/training/paths/get-started-ai-apps-agents/)
- Lab repo：[MicrosoftLearning/mslearn-ai-fundamentals](https://github.com/MicrosoftLearning/mslearn-ai-fundamentals)
- 課程頁：[AI-901T00-A](https://learn.microsoft.com/training/courses/ai-901t00)
- 模型退役排程：[Model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
