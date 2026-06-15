# 成都 Solo Coder 0601 质检规则摘要

分析对象：`/Users/wuzhijie/Downloads/成都Solo Coder 0601.xlsx`

## 文件结构

- `数据总表`：18,638 条数据行，核心字段包含 Repo 信息、Trae Session、User Prompt、任务分类、满意度、不满意原因、质检状态、质检备注。
- `不满意原因填写指引`、`常见问题`、`规范文档`：给出了不满意原因、任务记录、Repo/Commit、任务分布和废弃规则。

## 质检备注高频规则

1. `规则 4`：不满意时必须填写不满意原因；满意时不应填写不满意原因。
2. `规则 33 / 32`：Repo URL 或 Commit ID 不可访问、格式错误，或 Repo URL 不是仓库主页。
3. `规则 35`：commit message 未包含 Trae Session ID。
4. `规则 37 / 36 / 29`：不满意原因结构不合规、跨记录雷同、分段复读、模板化。
5. `规则 14 / 20 / 22`：任务类型与 Prompt 不匹配；代码理解任务修改范围必须为“无需修改”；简单代码理解任务废弃。
6. `规则 15 / 9 / 12`：过程与深度评价缺失；描述质量差；不满意原因复述需求而不是评价真实问题。
7. `规则 1 / 2 / 3`：Repo ID、Trae Session ID、必填字段格式或缺失问题。
8. `规则 17 / 18 / 23 / 25 / 26 / 27 / 34 / 38`：批内反作弊，包括 Prompt 雷同、原因雷同、Repo+Commit 重复、满意率或任务类型分布失衡。

## 单行检查规则

- 必填字段：`Repo ID`、`Repo URL`、`Commit ID`、`Trae Session ID`、`User Prompt`、任务分类字段、满意度、做题人、提交日期、是否提交字节等不能为空。
- Repo ID：自建仓库形如 `wha-1-2`；题库仓库形如 `A-1234-3`。
- Repo URL：应为 `https://github.com/owner/repo` 仓库主页。
- Commit ID：应填写完整 Git commit hash。
- Trae Session ID：不能填成 User Prompt；应是 Trae 导出的会话 ID。
- 不满意时必须填写不满意原因，且不少于 30 字。
- 满意时不应填写不满意原因。
- 未完成任务不能选择满意；未完成的不满意原因应同时包含 `产物不满意：` 和 `过程不满意：`。
- 不满意原因需要写清触发节点、实际行为、业务影响，不能只写“效果不好”“不行”“有问题”等笼统描述。
- 不满意原因不能把模型请求失败、网络波动、环境异常当作模型能力问题。
- 不满意原因不要整段粘贴控制台日志或堆栈。
- 过程不满意要描述模型在哪个步骤、工具调用、验证或判断中出了问题。
- 产物不满意要提供可核查证据，例如文件、页面、接口、字段、函数、路由或复现现象。
- `Bug修复` 的 Prompt 应明确修复什么问题。
- `代码理解` 应是阅读/分析类任务，修改范围必须为 `无需修改`，简单难度按规则废弃。

## 批量上下文规则

工具会结合历史表做这些检查：

- Trae Session ID 是否重复。
- Repo URL + Commit ID 是否重复。
- User Prompt 是否与历史记录长片段雷同、同义改写或模板化。
- 不满意原因是否与历史记录连续长片段雷同。
- 同一做题人的满意率是否超过 40%。
- 同一做题人的任务类型分布是否明显失衡。

## 使用方法

查看当前文件质检摘要：

```bash
/Users/wuzhijie/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 scripts/solo_coder_quality_check.py --summary
```

检查新输入行：

```bash
/Users/wuzhijie/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 scripts/solo_coder_quality_check.py \
  --workbook "/Users/wuzhijie/Downloads/成都Solo Coder 0601.xlsx" \
  --row-json '{"Repo ID":"wzj-1-1","Repo URL":"https://github.com/example/repo","Commit ID":"0123456789abcdef0123456789abcdef01234567","Trae Session ID":"Trae CN.T123","User Prompt":"修复登录页面密码为空时仍然提交的问题","任务类型":"Bug修复","业务领域":"后台管理","修改范围":"单文件","任务难度":"中等","任务是否完成":"未完成任务","过程与产物是否满意":"不满意","不满意原因":"产物不满意：登录页面仍然允许空密码提交，无法满足拦截校验需求。过程不满意：模型修改后没有运行表单提交流程验证，遗漏了空密码场景。","做题人":"wzj","提交日期":"2026-06-15","是否提交字节":"否"}'
```
