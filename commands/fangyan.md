---
description: 加载方言腔调（如 /fangyan 东北话）；可带浓度 /fangyan 东北话 80；切回普通话 /fangyan 普通话；留空列用法
argument-hint: <方言 [0-100]> 或 普通话，如 东北话 / dongbei 95 / off
allowed-tools: Bash
---

!bash "${CLAUDE_PLUGIN_ROOT}/commands-handlers/fangyan.sh" "${ARGUMENTS}"
