# LangChain4j + Quarkus AI

- Declarative first — model interactions are `@RegisterAiService` interfaces with `@SystemMessage`/`@UserMessage`, injected and called like any CDI bean. Return `Multi<String>` for token streaming, blocking types otherwise. Don't hand-wire `ChatModel` unless you need low-level control.
- Tools / function calling — annotate methods `@Tool`; the model routes on the description, so write it precisely.
- Structured output — declare a record/POJO return type and LangChain4j coerces the response. No manual JSON parsing.
- RAG — retrieve through an `EmbeddingStore` + `ContentRetriever` wired via `RetrievalAugmentor` — never ad-hoc prompt stuffing.
- Guardrails — validate and transform with `@InputGuardrail`/`@OutputGuardrail`; never trust raw model output at a boundary.
- Never hardcode keys — all config via `quarkus.langchain4j.*` (`quarkus.langchain4j.anthropic.api-key=${ANTHROPIC_API_KEY}`). Watch token cost: cap `max-tokens`, bound agentic loops, keep request/response logging to dev only.
- Default to current Claude — `quarkus-langchain4j-anthropic` with `quarkus.langchain4j.anthropic.chat-model.model-name=claude-opus-4-8` (or `claude-sonnet-5` / `claude-haiku-4-5`). The extension's built-in default is an old Haiku — set the model explicitly.

Docs:
- https://docs.quarkiverse.io/quarkus-langchain4j/dev/
- https://docs.langchain4j.dev/tutorials/ai-services
- https://docs.langchain4j.dev/integrations/language-models/anthropic

Defer to the `java-ai` skill for depth.
