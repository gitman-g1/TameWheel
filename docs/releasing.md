# 制作发布包

应用代码不依赖第三方库。当前发布流程在 macOS 27、Swift 6.4 / Command Line Tools 上验证；编译需要带 macOS 26+ SDK 的工具链。

```sh
bash scripts/test.sh release
bash scripts/package-release.sh
```

版本号来自 `Support/Info.plist`。脚本分别构建 arm64 与 x86_64，合并为通用应用，验证两种架构的临时签名，再生成 DMG、ZIP 和 SHA-256 校验文件，输出到 `dist/releases/`。这些文件作为 GitHub Release 附件上传，不提交进 Git。发布构建不会替换本机的 `dist/TameWheel.app`。

GitHub 发布前，先解压 ZIP、挂载 DMG，检查包内应用、签名和版本信息，再在 Apple Silicon 上运行检查。Intel 和未覆盖的系统版本需要额外实机验证，不将编译通过描述为已完成兼容性验证。

提交对应源码后，创建指向该提交的版本标签，先创建 Release 草稿并上传附件，核对附件大小、下载地址和校验值后再发布。首版作为普通 Release 发布并设为 Latest，让仓库首页显示下载入口；标题和说明仍明确标注「公开测试版」。GitHub 的 Pre-release 不能设为 Latest，后续需要首页展示时不要勾选该选项。

当前为临时签名、未公证版本。用户首次打开和升级后可能需要重新确认权限；说明见 [安装指南](install.md)。未来使用 Developer ID 签名和公证时，需要更新构建脚本及安装说明。
