# Adobe Plugins Research — defaltho

**Data:** 2026-06-13
**Repo analisado:** `jmlee9762/bezier-inspector-for-illustrator`

---

## Tecnologia confirmada: CEP

**Evidência directa:** presença de `CSXS/manifest.xml` com `ExtensionManifest Version="8.0"`.
Não há `manifest.json` com `"host": "ILST"` — descarta UXP.

---

## Arquitectura CEP (como funciona)

```
┌─────────────────────────────────────────┐
│  Panel — HTML/CSS/JS                    │
│  Renderizado em Chromium Embedded (CEF) │
│  Ficheiro: index.html + js/main.js      │
│  Comunica via CSInterface.evalScript()  │
└──────────────┬──────────────────────────┘
               │ evalScript() / callback
┌──────────────▼──────────────────────────┐
│  ExtendScript — jsx/host.jsx            │
│  Acede ao DOM do Illustrator:           │
│  app.activeDocument, pathItems,         │
│  anchor points, handle coords, etc.     │
└─────────────────────────────────────────┘
```

**Flags CEF usados:**
- `--enable-nodejs` — permite `require()` no painel
- `--mixed-context` — partilha contexto JS entre CEF e ExtendScript

---

## Detalhes do manifest

| Campo | Valor |
|-------|-------|
| Bundle ID | `com.ju.bezierinspector` |
| Host | `ILST` (Illustrator CC 2018 = v22.0 até futuro) |
| Tipo de painel | `Panel` (dock lateral) |
| Tamanho default | 300 × 720 px |
| Tamanho mínimo | 260 × 360 px |
| Entry point HTML | `./index.html` |
| Entry point script | `./jsx/host.jsx` |

---

## O que o plugin faz (features relevantes)

- **Anchor points** — visualiza cada ponto de ancoragem do path seleccionado
- **Bézier handles** — desenha os handles de cada curva
- **Connector lines** — linhas entre anchor e o seu handle
- **Typography metrics** — baseline, x-height, cap height, ascender, descender (a feature mais diferenciadora)
- **Cores e tamanhos configuráveis** — painel HTML com sliders/pickers
- **Output como Illustrator groups** — cria grupos no artboard (métricas, anchors, handles, connector lines), exportável

O plugin **lê o DOM do Illustrator** (PathItems, AnchorPoints, PathPoints) via ExtendScript e **desenha overlay no artboard** como objectos vetoriais nativos do Illustrator.

---

## CEP vs UXP — tabela de decisão

| | CEP | UXP |
|--|-----|-----|
| Tecnologia | HTML/JS + ExtendScript (.jsx) | JS/React + API Adobe nativa |
| Disponível desde | CC 2013 | Photoshop 2021 / Illustrator 2022+ |
| Illustrator | ✅ Suportado desde CC 2018 | ⚠️ Suporte parcial (2022+, ainda limitado) |
| Acesso ao DOM AI | ExtendScript completo | API UXP (subset, em expansão) |
| Futuro | Deprecated (sem data fixada) | Caminho oficial Adobe |
| Complexidade | Média (bridge evalScript) | Menor (acesso directo) |
| **Decisão para defaltho** | **Usar CEP agora** — mais maduro, melhor acesso ao DOM AI | Migrar para UXP quando o suporte Illustrator estabilizar |

**Conclusão:** para um plugin de Illustrator que lê PathItems e AnchorPoints em detalhe, CEP é a escolha certa em 2026. O UXP para Illustrator ainda não expõe o PathItem DOM com a mesma fidelidade que o ExtendScript.

---

## Features dos Cargo.site HTMLs aplicáveis a plugins

> **Pendente** — os 3 HTMLs ainda não foram descarregados para esta pasta.
> Quando disponíveis: `logomorph_v1.0.2_260608.html`, `liquid-metal-generator_v7_260613.html`, `path_relax_v17.html`

Hipóteses baseadas nos nomes:

| Ferramenta Cargo | Feature provável | Aplicação ao plugin |
|------------------|-----------------|---------------------|
| Logomorph | Morphing de paths / smooth bezier | Animação de handles no overlay, smooth transition ao seleccionar |
| Liquid Metal Generator | Efeito líquido em paths | Visual style para o overlay (handles com gradiente/shimmer) |
| Path Relax | Relaxamento/suavização de curvas | Feature nova: botão "relax" que simplifica o path seleccionado via ExtendScript |

---

## Próximos passos para um plugin defaltho

1. **Instalar o bezier-inspector** localmente para perceber o workflow do utilizador
2. **Decidir o primeiro plugin:** SvgView como plugin AI é o candidato natural (já existe a lógica de parse de paths em JS)
3. **Estrutura mínima CEP:**
   ```
   com.defaltho.svgview/
   ├── CSXS/manifest.xml
   ├── index.html          ← painel (reutilizar SvgView standalone)
   ├── js/main.js          ← CSInterface bridge
   ├── jsx/host.jsx        ← ExtendScript: ler PathItems do AI
   └── css/panel.css       ← reutilizar tool.css do _base
   ```
4. **Ler os 3 HTMLs do Cargo.site** e actualizar a secção acima
