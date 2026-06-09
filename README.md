---
image: https://learn.microsoft.com/zh-tw/media/learn/certification/badges/microsoft-certified-fundamentals-badge.svg
tags: AI-901, Reference
GA: G-DXYJBX6BH8
---

# AI-901 Reference

> **Course AI-901T00-A: Introduction to AI in Azure**
> Foundational AI concepts and the Azure services that make them practical: responsible AI,
> generative AI and **agents**, text analysis, speech, computer vision, and information extraction —
> built and consumed through **Microsoft Foundry**. This refreshed course **replaces AI-900** and
> prepares you for the *Microsoft Certified: Azure AI Fundamentals* (exam **AI-901**).

## Course
:::success
Date: 20260609
Course ID: 100781
:::

:::info
Course Survey: [https://aka.ms/ai901survey](https://aka.ms/ai901survey)
:::

## Course Materials
[Course AI-901 English version](https://learn.microsoft.com/en-us/training/courses/ai-901t00)
[Course AI-901 简体中文版本](https://learn.microsoft.com/zh-cn/training/courses/ai-901t00)
[Course AI-901 正體中文版本](https://learn.microsoft.com/zh-tw/training/courses/ai-901t00)

[Learning path: Get started with AI apps and agents (EN)](https://learn.microsoft.com/en-us/training/paths/get-started-ai-apps-agents/)
[學習路徑：開始使用 AI 應用程式與代理程式 (正體中文)](https://learn.microsoft.com/zh-tw/training/paths/get-started-ai-apps-agents/)

## Infos
[LxP Portal](https://esi.microsoft.com/)

[ESI Support](https://aka.ms/esisupport)

## Lab
### Skillable lab system
[ESI Labs](https://aka.ms/esilab)
:::success
Training key: E27D6C4324FD0D17
:::

:::info
Only need to redeem once
Valid for 6 months
:::

### Instruction
[AI-901 Labs EN - mslearn-ai-fundamentals](https://microsoftlearning.github.io/mslearn-ai-fundamentals/)

- [01 - Get started with Microsoft Foundry](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/00-explore-foundry.html)
- [02 - Get started with generative AI and agents](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/02a-generative-ai.html)
- [03 - Get started with text analysis](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/03b-text-analysis.html)
- [04 - Get started with speech](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/04a-speech.html)
- [05 - Get started with computer vision](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/05a-image-analysis.html)
- [06 - Get started with Content Understanding](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/06a-content-understanding.html)
- [Extra - Get started with Foundry IQ](https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Exercises/07-foundry-iq.html)

[AI-901 Lab files (main.zip)](https://github.com/MicrosoftLearning/mslearn-ai-fundamentals/archive/refs/heads/main.zip)

:::warning
At time of writing there are **no localized (zh-cn / zh-tw) lab repositories** for AI-901 — only the
**English** lab instructions above are available (a Japanese `ja-jp` repo also exists). The course
slides and the learning path *are* localized, but the hands-on labs are **English-only**.
:::

## Links

### Microsoft Foundry & Azure foundations
[What is Microsoft Foundry?](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry)

[Foundry resources, projects, and how they map to Azure](https://learn.microsoft.com/azure/ai-foundry/how-to/create-projects)

[Foundry Models overview (catalog)](https://learn.microsoft.com/azure/ai-foundry/how-to/model-catalog-overview)

[Foundry endpoints](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/endpoints)

[Foundry SDKs & supported languages](https://learn.microsoft.com/azure/ai-foundry/openai/supported-languages)

[Deployment types for Foundry Models](https://learn.microsoft.com/azure/ai-foundry/foundry-models/concepts/deployment-types)

[Foundry Models lifecycle and retirement schedule](https://learn.microsoft.com/azure/ai-foundry/concepts/model-lifecycle-retirement)

[What is Microsoft Entra ID?](https://learn.microsoft.com/entra/fundamentals/whatis)

[Azure role-based access control (RBAC)](https://learn.microsoft.com/azure/role-based-access-control/overview)

### Responsible AI
[What is Responsible AI? (the six principles)](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)

[Responsible use of AI in Azure AI services / Foundry](https://learn.microsoft.com/azure/foundry/responsible-use-of-ai-overview)

[Configure content filters (guardrails)](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/content-filters)

[Content filter configurability](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/content-filter-configurability)

### 1. Get started with AI in Azure
[Module - Fundamental AI concepts](https://learn.microsoft.com/en-us/training/modules/get-started-ai-fundamentals/)

[Module - Get started with AI in Azure](https://learn.microsoft.com/en-us/training/modules/get-started-with-ai-in-azure/)

[Explore AI workloads (Computing History app)](https://microsoftlearning.github.io/ai-apps/computing-history/)

#### API key vs Microsoft Entra ID token
A Foundry **endpoint** is the HTTP address an app calls; the request must be **authenticated**. Two
options: an **API key** (a shared secret — simple, but anyone with the key has full access) or a
**Microsoft Entra ID token** (identity-based, supports RBAC, no long-lived secret to leak). Prefer
**Entra ID** for anything beyond quick experimentation — and note many enterprise tenants *require* it.

- [Authentication & keys vs Entra ID for Azure AI services](https://learn.microsoft.com/azure/ai-services/authentication)
- [Azure RBAC](https://learn.microsoft.com/azure/role-based-access-control/overview)

### 2. Get started with generative AI and agents
[Module - Fundamentals of generative AI](https://learn.microsoft.com/en-us/training/modules/fundamentals-generative-ai/)

[Module - Get started with generative AI and agents](https://learn.microsoft.com/en-us/training/modules/get-started-with-generative-ai-and-agents/)

[Understand embeddings](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/understand-embeddings)

[Prompt engineering techniques](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/prompt-engineering)

[Foundry Agent Service](https://learn.microsoft.com/azure/ai-foundry/agents/overview)

#### LLM vs SLM
**Large language models (LLMs)** maximize capability and breadth; **small language models (SLMs)** are
more compact and run in resource-constrained or on-device scenarios with lower cost/latency. Both are
transformer models that predict the next token from **tokens → embeddings → attention**.

- [Foundry Models overview](https://learn.microsoft.com/azure/ai-foundry/concepts/foundry-models-overview)

#### First-party vs partner & community models
The Foundry catalog mixes **models sold directly by Azure** (e.g. Azure OpenAI — billed via your Azure
subscription, Microsoft-supported) with **partner & community** models from third-party providers.
Choose by capability, **deployment type**, version/auto-update policy, rate limits, and guardrails.

- [Models sold directly by Azure](https://learn.microsoft.com/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure)
- [Model catalog](https://learn.microsoft.com/azure/ai-foundry/how-to/model-catalog-overview)

#### ChatCompletions API vs Responses API
The course code uses `client.responses.create(...)`. **Chat Completions** is the broadly-used,
**stateless** API (the client resends the full conversation each turn). **Responses** is the newer,
**stateful** API that unifies Chat Completions + Assistants and is **agent-aware** (pass an
`agent_reference`). Prefer **Responses** for new apps and agents.

- [Work with Chat Completions models](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/chatgpt)
- [Use the Responses API](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/responses)

### 3. Get started with text analysis
[Module - Fundamentals of Text Analysis with the Language Service](https://learn.microsoft.com/en-us/training/modules/introduction-language/)

[Module - Get started with text analysis in Azure](https://learn.microsoft.com/en-us/training/modules/get-started-text-analysis-azure/)

[What is Azure AI Language?](https://learn.microsoft.com/azure/ai-services/language-service/overview)

[Named entity recognition (NER)](https://learn.microsoft.com/azure/ai-services/language-service/named-entity-recognition/overview)

[Sentiment analysis & opinion mining](https://learn.microsoft.com/azure/ai-services/language-service/sentiment-opinion-mining/overview)

[Key phrase extraction](https://learn.microsoft.com/azure/ai-services/language-service/key-phrase-extraction/overview)

[PII detection](https://learn.microsoft.com/azure/ai-services/language-service/personally-identifiable-information/overview)

[Language detection](https://learn.microsoft.com/azure/ai-services/language-service/language-detection/overview)

[Summarization](https://learn.microsoft.com/azure/ai-services/language-service/summarization/overview)

[Connect agents to tools with Model Context Protocol (MCP)](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/model-context-protocol)

#### General-purpose AI models vs Azure Language in Foundry Tools
AI-901 teaches **two approaches** to text analysis (because many Azure Language *in Foundry* features
are being retired). Pick by the kind of result you need:

| Use **general-purpose AI models** (e.g. gpt-4.1-mini) when… | Use **Azure Language in Foundry Tools** when… |
| --- | --- |
| You need flexible, conversational analysis | You need consistent, **structured** output |
| You want to combine multiple tasks in one prompt | You're building automated pipelines |
| Natural-language responses are fine | You require specific **confidence scores** |
| You can tolerate some variability | You handle **regulated data** (PII / PHI) & need deterministic, production-ready results |

#### OpenAI Python SDK vs Azure Language SDK
Two client libraries match the two approaches above: the **OpenAI Python library** (prompt a
general-purpose model via the **Responses API**) and the **Azure Language SDK** (purpose-built methods
such as `recognize_entities`, `recognize_pii_entities`, `analyze_sentiment` that return categories +
confidence scores).

- [OpenAI Responses API](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/responses)
- [Azure AI Language overview & SDKs](https://learn.microsoft.com/azure/ai-services/language-service/overview)

### 4. Get started with speech
[Module - Fundamentals of AI Speech](https://learn.microsoft.com/en-us/training/modules/introduction-ai-speech/)

[Module - Get started with speech in Azure](https://learn.microsoft.com/en-us/training/modules/get-started-speech-azure/)

[What is the Azure AI Speech service?](https://learn.microsoft.com/azure/ai-services/speech-service/overview)

[Speech to text (recognition)](https://learn.microsoft.com/azure/ai-services/speech-service/speech-to-text)

[Text to speech (synthesis)](https://learn.microsoft.com/azure/ai-services/speech-service/text-to-speech)

### 5. Get started with computer vision
[Module - Fundamentals of Computer Vision](https://learn.microsoft.com/en-us/training/modules/introduction-computer-vision/)

[Module - Get started with computer vision in Azure](https://learn.microsoft.com/en-us/training/modules/get-started-vision-azure/)

[What is Azure AI Vision?](https://learn.microsoft.com/azure/ai-services/computer-vision/overview)

[Use vision-enabled (multimodal) chat models](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/gpt-with-vision)

#### Image analysis vs image/video generation
Computer vision now spans **interpreting** images (multimodal models describe, classify, and reason
over an image) **and generating** them. AI-901 introduces both — analysis with vision-enabled models,
and **image/video generation**.

- [Generate images (GPT-Image)](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/dall-e)
- [Video generation with Sora (preview)](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/video-generation)

### 6. Get started with information extraction
[Module - Fundamentals of AI-powered information extraction](https://learn.microsoft.com/en-us/training/modules/introduction-information-extraction/)

[Module - Get started with information extraction in Azure](https://learn.microsoft.com/en-us/training/modules/get-started-information-extraction/)

[What is Azure AI Content Understanding?](https://learn.microsoft.com/azure/ai-services/content-understanding/overview)

[Content Understanding analyzers](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/analyzer-reference)

[Prebuilt analyzers](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/prebuilt-analyzers)

[What is Azure AI Document Intelligence? (OCR / forms)](https://learn.microsoft.com/azure/ai-services/document-intelligence/overview?view=doc-intel-4.0.0)

[What is Foundry IQ? (knowledge for agents)](https://learn.microsoft.com/azure/foundry/agents/concepts/what-is-foundry-iq)

[What is Azure AI Search?](https://learn.microsoft.com/azure/search/search-what-is-azure-search)

## Mind Map
```markmap
# Introduction to AI in Azure (AI-901)

## 1. Get started with AI
### AI concepts
- Software that imitates human capabilities
- [AI workloads](https://learn.microsoft.com/en-us/training/modules/get-started-ai-fundamentals/): GenAI & agents, language, speech, vision, info extraction
- [Responsible AI](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai): Fairness, Reliability & Safety, Privacy & Security, Inclusiveness, Transparency, Accountability
### AI in Azure
- Tenant → Subscription → Resource group → Resources ([Entra ID](https://learn.microsoft.com/entra/fundamentals/whatis))
- [Microsoft Foundry](https://learn.microsoft.com/azure/ai-foundry/what-is-azure-ai-foundry): resources & projects (Models, Agents, Tools, Knowledge)
- [Endpoints](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/endpoints): REST, key **vs** Entra ID token, SDKs

## 2. Generative AI & agents
### Concepts
- Generates text, images, code; LLM **vs** SLM
- Tokens → [embeddings](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/understand-embeddings) → attention → transformers
- [Agents](https://learn.microsoft.com/azure/ai-foundry/agents/overview) = model + instructions + tools + knowledge
### In Azure
- [Foundry Models](https://learn.microsoft.com/azure/ai-foundry/how-to/model-catalog-overview): first-party vs partner; [deployment types](https://learn.microsoft.com/azure/ai-foundry/foundry-models/concepts/deployment-types)
- Playground; [Chat Completions](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/chatgpt) **vs** [Responses API](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/responses)
- Foundry Agent Service

## 3. Text analysis
### NLP tasks
- [NER](https://learn.microsoft.com/azure/ai-services/language-service/named-entity-recognition/overview), [sentiment](https://learn.microsoft.com/azure/ai-services/language-service/sentiment-opinion-mining/overview), [key phrases](https://learn.microsoft.com/azure/ai-services/language-service/key-phrase-extraction/overview), [PII](https://learn.microsoft.com/azure/ai-services/language-service/personally-identifiable-information/overview), summarization
### Two approaches
- General-purpose models (prompts) **vs** [Azure Language](https://learn.microsoft.com/azure/ai-services/language-service/overview) (structured + confidence)
- OpenAI SDK **vs** Azure Language SDK; [MCP](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/model-context-protocol) in agents

## 4. Speech
- [Speech to text](https://learn.microsoft.com/azure/ai-services/speech-service/speech-to-text) (recognition)
- [Text to speech](https://learn.microsoft.com/azure/ai-services/speech-service/text-to-speech) (synthesis)
- Speech-capable agents

## 5. Computer vision
- [Azure AI Vision](https://learn.microsoft.com/azure/ai-services/computer-vision/overview); [multimodal models](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/gpt-with-vision)
- Generation: [images](https://learn.microsoft.com/azure/ai-foundry/openai/how-to/dall-e), [video (Sora)](https://learn.microsoft.com/azure/ai-foundry/openai/concepts/video-generation)

## 6. Information extraction
- [Content Understanding](https://learn.microsoft.com/azure/ai-services/content-understanding/overview): [analyzers](https://learn.microsoft.com/azure/ai-services/content-understanding/concepts/analyzer-reference), documents + audio + video
- [OCR / Document Intelligence](https://learn.microsoft.com/azure/ai-services/document-intelligence/overview?view=doc-intel-4.0.0)
- [Foundry IQ](https://learn.microsoft.com/azure/foundry/agents/concepts/what-is-foundry-iq) + [AI Search](https://learn.microsoft.com/azure/search/search-what-is-azure-search)
```

## Exam
[Exam AI-901: Microsoft Azure AI Fundamentals](https://learn.microsoft.com/credentials/certifications/exams/ai-901/)
[Certification: Microsoft Certified: Azure AI Fundamentals](https://learn.microsoft.com/credentials/certifications/azure-ai-fundamentals/)
[AI-901 Study Guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/ai-901)
[Exam Readiness Zone - Microsoft Fundamentals](https://learn.microsoft.com/en-us/shows/exam-readiness-zone/what-to-expect-on-your-microsoft-fundamentals-exam)
[Claiming your exam voucher - Video](https://aka.ms/esi-claim-voucher)
[Exam duration and question types](https://learn.microsoft.com/en-us/credentials/support/exam-duration-exam-experience)
[Accessing Microsoft Learn during your certification exam](https://learn.microsoft.com/en-us/credentials/support/exam-duration-exam-experience#accessing-microsoft-learn-during-your-certification-exam)
[Microsoft Certification Exam Sandbox](https://aka.ms/examdemo)
[Renew your Microsoft Certifications for free](https://aka.ms/RenewYourCertVideo)

## Contact
- Money Yu
    - Mail: [Money.Yu@microsoft.com](mailto:Money.Yu@microsoft.com)
    - LinkedIn: [@abc12207](https://www.linkedin.com/in/abc12207/)
