# AssaultCube iOS 移植（进行中）

上游：https://github.com/assaultcube/AC 的 `acmobile` 分支（官方移动版，SDL2 + GL4ES + OpenAL + 触屏 UI，原本只出 Android）。

## 已核实
- `acmobile` 分支真实存在（sha a2fa75e0），含 `source/src/touch` 触屏 UI、`source/android` 构建脚本。
- 引擎仅 `platform.h` 一处 Android 专属头文件；`source/xcode` 是 **macOS** 启动器，不是 iOS。
- 上游没有任何 iOS 代码，需要新建 iOS 平台层。
- GL4ES 官方 README 明确支持 iOS；SDL2 官方支持 iOS。

## 依赖（全部需要在 iOS 上重新编译为 arm64 静态库）
SDL2 / SDL2_image / OpenAL / libogg / libvorbis / GL4ES / ENet(源码内置)

## 里程碑
1. M1：SDL2 + GL4ES 的 iOS arm64 静态库编译通过
2. M2：AssaultCube 全部源码在 iOS 工具链下编译通过
3. M3：`.app` 打包、资源目录定位、能启动进主菜单
4. M4：触屏输入 / 横屏 / 音频 / 生命周期
5. M5：未签名 IPA 产出

## 现状
M1 进行中。构建机：GitHub Actions `macos-26`（Xcode 26.x）。
