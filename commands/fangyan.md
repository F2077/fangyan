---
description: 加载方言腔调（如 /fangyan 东北话）；可带浓度 /fangyan 东北话 80；留空列用法
argument-hint: <方言 [0-100]>，如 东北话 或 dongbei 95
allowed-tools: Bash
---

!bash "${CLAUDE_PLUGIN_ROOT}/commands-handlers/fangyan.sh" "${ARGUMENTS}"
