# 三指点按光标下单词并自动翻译

- 状态：completed
- 创建日期：2026-09-15
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

Easydict Lite 已移除通用划词翻译入口，但用户仍希望使用 macOS 的触摸板三指点按手势，直接读取光标位置对应的单词并自动翻译，不要求预先选中文字。

## 目标与范围

- 目标结果：三指轻点未选中的单词后，打开轻量查询窗口、填入光标下单词并立即翻译。
- 允许修改路径：事件监控、查询窗口调用和本任务文档。
- 同任务 history：`docs/histories/2026-09/2026-09-15-three-finger-lookup.md`
- 用户限制：不恢复划词翻译菜单、快捷键或悬浮按钮。
- 非目标：重新引入完整划词翻译设置或菜单入口。
- 验收标准：普通单击不触发；三指短时轻点才尝试取词；无需预先选中；只显示 Lite 查询窗口并自动查询。

## 工作计划

1. 在现有事件监控中识别三触点、短时、低位移的手势序列。
2. 在三指轻点结束后，由源应用在原鼠标位置执行双击选词，再通过现有选区读取链路取得准确文本。
3. 调用现有查询窗口填入文本并自动查询。
4. 关闭本机 macOS 自带三指查词，构建、安装并记录真实触摸板验收结果。

## 风险与决策

- Apple 的 Quick Look 查词事件不进入普通事件队列且没有事件掩码；使用动态加载、只读且可失败回退的 `MultitouchSupport` 适配器获取全局接触帧，同时保留 AppKit 通用手势回退。框架不可用时不影响应用启动。
- 首版 Accessibility 点位接口在 Codex 文本视图中会返回附近单词（点击 `Lite` 得到 `Release`）。最终改为合成双击，让源应用使用自身文字命中规则选词，再复用已验证的选区读取链路。
- 私有触摸板框架无法拦截系统 Quick Look；本机除写入持久偏好外，还通过系统 `MTTGestureBackEnd` 执行关闭 setter 并发送触摸板变更通知，使当前登录会话立即生效。
- 三指滑动通过时长与归一化位移阈值排除，避免误触发 Mission Control 等手势。

## 进度

- [x] 确认现有选区读取与查询窗口接口。
- [x] 实现三指点按识别、自动选词与自动查询流程。
- [x] 完成 Release 构建、代码检查和本机安装。
- [x] 完成真实触摸板验收。

## 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Release -derivedDataPath /tmp/easydict-three-finger-derived.chQZgv CODE_SIGNING_ALLOWED=NO`：通过。
- `/Applications/Easydict Lite.app`：已使用稳定本地证书重装并启动，原始触摸板监听启动成功。
- macOS 系统查词：三指轻点与 Force Click 偏好均已关闭，`ForceSuppressed=1`，并经 `MTTGestureBackEnd` 和变更通知刷新当前会话。
- 真实触摸板：用户确认点击未选中的 `Lite` 后取词准确、自动翻译，系统词典不再出现。
- 现有全量测试曾在本任务首版运行；失败点为无关的 `SystemUtilitiesTests` 桌面音量 AppleScript（`Failed to get alert volume`），Swift/XCTest 单元部分无失败。按项目规则未擅自新增测试。

## 完成条件

- 代码检查与构建通过。
- 已安装本机测试版本。
- 自动检查结果和真实触摸板验收状态分别记录。
