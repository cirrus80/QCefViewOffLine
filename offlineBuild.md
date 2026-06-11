# QCefView 离线构建指南

本文档汇总 QCefView 的构建方法，以及 CefViewCore、CEF 预编译包的离线使用方式。

---

## 如何构建 QCefView

QCefView 使用 **CMake** 构建，依赖 **Qt 5/6** 和 **CEF**（通过 CefViewCore 引入）。

### 前置条件

| 依赖 | 要求 |
|------|------|
| **CMake** | ≥ 3.21（`CMakeLists.txt` 要求） |
| **Qt** | Qt 5 或 Qt 6，需包含 `Core`、`Gui`、`Widgets` |
| **编译器** | Windows：Visual Studio（MSVC，与 Qt 套件匹配，如 `msvc2019_64`） |
| **Git** | 用于 FetchContent 拉取 CefViewCore 和下载 CEF SDK |

**重要：** Qt 的架构必须与 CEF 一致（例如都是 `x86_64`）。

### 1. 配置 Qt 路径

设置环境变量 `QTDIR`，或在 CMake 时传 `-DQT_SDK_DIR=...`：

```bat
set QTDIR=C:\Qt\6.2.2\msvc2019_64
```

`cmake/QtConfig.cmake` 会优先读 `QT_SDK_DIR`，否则从 `QTDIR` 读取。

### 2. 克隆项目

```bat
git clone https://github.com/CefView/QCefView.git
cd QCefView
```

**不需要** `--recursive` 子模块。`CefViewCore` 已通过 **CMake FetchContent** 自动拉取（见 `thirdparty/CMakeLists.txt`）。首次配置时会从 GitHub 下载 CefViewCore，并从 [cef-builds.spotifycdn.com](https://cef-builds.spotifycdn.com/index.html) 下载 CEF 预编译包（默认版本 `142.0.15+g6dfdb28+chromium-142.0.7444.176`）。

### 3. 生成构建文件（Windows x64）

在项目根目录执行：

```bat
generate-win-x86_64.bat
```

该脚本等价于：

```bat
cmake -S . ^
-B .build/windows.x86_64 ^
-A x64 ^
-DPROJECT_ARCH=x86_64 ^
-DBUILD_DEMO=ON ^
-DCMAKE_INSTALL_PREFIX:PATH="%cd%/out/windows.x86_64"
```

其他平台脚本：

- `generate-win-x86.bat` / `generate-win-arm64.bat`
- `generate-mac-x86_64.sh` / `generate-mac-arm64.sh`
- `generate-linux-x86_64.sh`

### 4. 编译

```bat
cmake --build .build/windows.x86_64 --config Release
```

Debug 构建：

```bat
cmake --build .build/windows.x86_64 --config Debug
```

也可以在 `.build/windows.x86_64` 下打开生成的 `.sln`，用 Visual Studio 编译。

### 5. 输出位置

- **库和 Demo 二进制：** `.build/windows.x86_64/output/Release/bin/`（或 `Debug`）
- **安装到指定目录（可选）：**

```bat
cmake --install .build/windows.x86_64 --config Release
```

安装到 `out/windows.x86_64/`，包含 `QCefView` 库和 `QCefViewTest` Demo。

### 常用 CMake 选项

可在 `generate-win-x86_64.bat` 后追加参数，或手动传给 `cmake -S . -B ...`：

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `BUILD_DEMO` | `OFF`（脚本里为 `ON`） | 是否构建示例 `QCefViewTest` |
| `BUILD_STATIC` | `OFF` | 静态库 vs 动态库 |
| `CEF_SDK_VERSION` | 见 `thirdparty/CMakeLists.txt` | 指定 CEF 版本 |
| `CUSTOM_CEF_SDK_DIR` | 空 | 使用本地自编译或已下载的 CEF |
| `QT_SDK_DIR` | 从 `QTDIR` 读取 | Qt 安装路径 |
| `STATIC_CRT` | `OFF` | MSVC 静态链接 CRT |
| `USE_WIN_DCOMPOSITION` | `OFF` | Windows 硬件渲染 DirectComposition |

示例：只编译库、不编译 Demo：

```bat
generate-win-x86_64.bat -DBUILD_DEMO=OFF
```

### 运行 Demo

编译成功后，在 `output/Release/bin/` 或安装目录运行 `QCefViewTest.exe`。CEF 相关 DLL 和资源会随构建一起部署到该目录。

### 常见问题

1. **找不到 Qt：** 确认 `QTDIR` 指向正确的 kit（如 `...\msvc2019_64`）。
2. **首次配置很慢：** 需下载 CefViewCore 和 CEF SDK（体积较大），需稳定网络。
3. **文档略旧：** `scripts/doxygen/docs/01-BuildAndConfig.md` 仍提到子模块；当前版本已改用 FetchContent，以 `readme.md` 和 `thirdparty/CMakeLists.txt` 为准。
4. **Windows Sandbox：** 在 Windows 上默认关闭（`USE_SANDBOX` 被强制为 `OFF`），与 Qt 的 CRT 链接方式有关。

更完整的文档：[https://cefview.github.io/QCefView/](https://cefview.github.io/QCefView/)

---

## CefViewCore 拉取目录

CefViewCore 通过 FetchContent 拉取，**不会**出现在项目根目录的子模块里，而是放在 **CMake 构建目录** 下的 `_deps` 中。

### 源码目录

在 `thirdparty/CMakeLists.txt` 里写死了 `SOURCE_DIR`：

```cmake
FetchContent_Declare(
    CefViewCore
    GIT_REPOSITORY https://github.com/CefView/CefViewCore.git
    GIT_TAG ${CEFVIEW_CORE_VERSION}
    SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/cefviewcore-src-${CEFVIEW_CORE_SRC_DIR_SUFFIX}"
)
```

其中：

- **`CMAKE_BINARY_DIR`** = 你 `cmake -B` 指定的构建目录
- **`CEFVIEW_CORE_SRC_DIR_SUFFIX`** = `CEFVIEW_CORE_VERSION` 的前 7 位（默认 commit `454c7246...` → `454c724`）

### 实际路径示例

如果用默认的 `generate-win-x86_64.bat`（`-B .build/windows.x86_64`），源码会在：

```
d:\work\QCefView\.build\windows.x86_64\_deps\cefviewcore-src-454c724\
```

如果手动指定了别的构建目录，把上面的 `.build\windows.x86_64` 换成你的 `-B` 路径即可。

### 相关目录说明

| 路径 | 内容 |
|------|------|
| `{构建目录}/_deps/cefviewcore-src-454c724/` | CefViewCore **源码**（git clone 到这里） |
| `{构建目录}/_deps/cefviewcore-build-454c724/` | CefViewCore 的 **编译输出**（FetchContent 自动生成） |
| `{构建目录}/_deps/cefviewcore-subbuild/` | FetchContent 下载/配置用的临时 subbuild |

CEF 预编译 SDK 一般会下载到 CefViewCore 源码树内的 `dep/` 目录，例如：

```
.build\windows.x86_64\_deps\cefviewcore-src-454c724\dep\
```

### 补充

- 项目根目录下**没有** `CefViewCore/` 文件夹（旧版子模块方式已废弃）。
- 可通过 `-DCEFVIEW_CORE_VERSION=<commit/tag>` 指定版本，目录后缀会随 commit 前 7 位变化，例如 `cefviewcore-src-a1b2c3d`。
- `include/CefVersion.h` 会在配置时从 CefViewCore 拷贝到项目 `include/` 目录，那是头文件副本，不是 CefViewCore 本体。

---

## 如何使用已经下载的 CefViewCore

当前项目**没有**类似 `CUSTOM_CEF_SDK_DIR` 那样专门给 CefViewCore 的 CMake 选项，但可以用 CMake FetchContent 的标准机制指向本地已下载的源码。

### 方法一：用 `FETCHCONTENT_SOURCE_DIR`（推荐）

CMake 允许用变量覆盖 FetchContent 的源码目录。`FetchContent_Declare` 里名字是 `CefViewCore`，对应变量为：

```bat
cmake -S . -B .build/windows.x86_64 -A x64 ^
  -DPROJECT_ARCH=x86_64 ^
  -DBUILD_DEMO=ON ^
  -DFETCHCONTENT_SOURCE_DIR_CEFVIEWCORE=D:/path/to/your/CefViewCore ^
  -DFETCHCONTENT_FULLY_DISCONNECTED=ON
```

或在 `generate-win-x86_64.bat` 后面追加：

```bat
generate-win-x86_64.bat ^
  -DFETCHCONTENT_SOURCE_DIR_CEFVIEWCORE=D:/path/to/your/CefViewCore ^
  -DFETCHCONTENT_FULLY_DISCONNECTED=ON
```

说明：

| 参数 | 作用 |
|------|------|
| `FETCHCONTENT_SOURCE_DIR_CEFVIEWCORE` | 指定本地 CefViewCore 根目录（含 `CMakeLists.txt` 的那一层） |
| `FETCHCONTENT_FULLY_DISCONNECTED=ON` | 配置时不再 `git clone` / `git pull` |

**版本要对齐：** 默认期望 commit 为 `454c7246d1dd1c1a1888580e8972fac6691a5f44`（见 `thirdparty/CMakeLists.txt`）。本地仓库应 checkout 到该 commit，或通过 `-DCEFVIEW_CORE_VERSION=<你的commit>` 指定你实际使用的版本。

### 方法二：放到 FetchContent 默认目录

把已下载的 CefViewCore **复制或 junction** 到 CMake 期望的路径（首次配置前）：

```
d:\work\QCefView\.build\windows.x86_64\_deps\cefviewcore-src-454c724\
```

其中 `454c724` 是 `CEFVIEW_CORE_VERSION` 的前 7 位。目录里已有完整源码时，FetchContent 通常不会重新下载。

### 方法三：复用上次构建已拉取的副本

如果之前已经成功跑过 `cmake` 配置，CefViewCore 已经在：

```
.build\windows.x86_64\_deps\cefviewcore-src-454c724\
```

**同一构建目录**再次配置时会直接复用，无需额外设置。可加：

```bat
-DFETCHCONTENT_FULLY_DISCONNECTED=ON
```

避免 CMake 尝试更新远程仓库。

### 不推荐：根目录子模块方式

旧文档里的 `QCefView/CefViewCore/` 子模块方式**已不再使用**（项目无 `.gitmodules`，`thirdparty/CMakeLists.txt` 只走 FetchContent）。把仓库 clone 到项目根目录的 `CefViewCore/` **不会**被当前 CMake 自动识别。

---

## CEF 预编译包放到 CefViewCore\dep 下的形式

根据 CefViewCore 的 `cmake/SetupCef.cmake`，**最终使用的是解压后的目录**；压缩包只是中间形式，CMake 会自动解压。

### 默认流程（不设置 `CUSTOM_CEF_SDK_DIR`）

工作目录为：

```
CefViewCore/dep/
```

CMake 会按顺序处理：

1. 检查是否已有**解压后的目录**  
   例如 Windows x64：
   ```
   CefViewCore/dep/cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64/
   ```
   若该目录存在 → **直接使用，不再下载/解压**。

2. 若目录不存在，查找**压缩包**：
   ```
   CefViewCore/dep/cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64.tar.bz2
   ```
   若存在 → 自动解压到 `dep/`。

3. 若压缩包也不存在 → 从 Spotify CDN 下载 `.tar.bz2`，再解压。

因此手动放置时，两种方式都可以：

| 形式 | 是否可用 | 说明 |
|------|----------|------|
| **解压后的目录** | ✅ 推荐 | 放到 `dep/cef_binary_<版本>_<平台>/`，CMake 直接识别 |
| **`.tar.bz2` 压缩包** | ✅ 可以 | 放到 `dep/`，CMake 配置时自动解压 |
| **`.zip` 压缩包** | ❌ 不行 | 脚本只认 `.tar.bz2`，不会处理 `.zip` |

### 目录命名必须匹配

目录/压缩包名称由 `CEF_SDK_VERSION` 和平台决定，Windows x64 示例：

```
cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64
```

注意是 `windows64`，不是 `windows_x64`。

解压后目录内应包含 CEF 标准结构，例如：

```
cef_binary_..._windows64/
├── cmake/
├── include/
│   └── cef_version.h
├── Release/
├── Debug/
├── Resources/
└── ...
```

### 使用 `CUSTOM_CEF_SDK_DIR` 时

必须指向**已解压的目录**，不能是压缩包：

```bat
-DCUSTOM_CEF_SDK_DIR=D:/path/to/cef_binary_142.0.15+..._windows64
```

CMake 会直接把这个路径当作 `CEF_ROOT`，并检查其中是否有 `include/cef_version.h` 等文件。

### 实际建议

- **想省事、离线构建**：手动下载 `.tar.bz2`，放到 `CefViewCore/dep/`，让 CMake 自动解压。
- **想跳过解压步骤**：自己解压到 `dep/`，并保证目录名与上面规则一致。
- **目录名不对或路径任意**：用 `-DCUSTOM_CEF_SDK_DIR` 指向解压后的根目录。

Spotify 提供的标准包格式就是 `.tar.bz2`（Windows 上同样），不要用 `.zip`。

---

## 完整离线构建示例（Windows）

假设：

- CefViewCore 在 `D:\deps\CefViewCore`，且已 checkout 到正确 commit
- CEF 已解压到 `D:\deps\CefViewCore\dep\cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64`

```bat
set QTDIR=C:\Qt\6.5.3\msvc2019_64

generate-win-x86_64.bat ^
  -DFETCHCONTENT_SOURCE_DIR_CEFVIEWCORE=D:/deps/CefViewCore ^
  -DFETCHCONTENT_FULLY_DISCONNECTED=ON ^
  -DCUSTOM_CEF_SDK_DIR=D:/deps/CefViewCore/dep/cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64

cmake --build .build/windows.x86_64 --config Release
```

若 CEF 已按命名规则放在 `CefViewCore\dep\` 下（解压目录或 `.tar.bz2`），可省略 `-DCUSTOM_CEF_SDK_DIR`，CMake 会自动识别。

CEF 版本与环境和编译器有对应关系查看通过下面地址查看
https://chromiumembedded.github.io/cef/branches_and_building

CEF 下载地址 https://cef-builds.spotifycdn.com/index.html

找老版本 点击 Show more builds 展开
目前使用版本 cef_binary_142.0.15+g6dfdb28+chromium-142.0.7444.176_windows64.tar.bz2
