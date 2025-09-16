# MER

一个使用 **Flutter** 构建的跨平台应用，支持 **Android** 和 **Web**。  
项目目标是提供现代化的界面和流畅的交互。  

---

## 📦 技术栈

- **Flutter 3.x**  
- **Dart**  
- **Android SDK / Gradle**  
- **Web (Flutter Web 构建)**  

---

## ⚙️ 环境配置

### 1. Flutter 镜像源（清华）
用管理员权限打开命令行，输入以下命令，在环境变量中加入清华镜像：  
```powershell
setx PUB_HOSTED_URL "https://mirrors.tuna.tsinghua.edu.cn/dart-pub/"
setx FLUTTER_STORAGE_BASE_URL "https://mirrors.tuna.tsinghua.edu.cn/flutter"
````

### 2. Gradle 镜像源（腾讯）

编辑 `android/gradle/wrapper/gradle-wrapper.properties`：

```properties
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-8.11.1-all.zip
```

---

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/your-username/Pandora.git
cd Pandora
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行项目

#### 运行 Android 模拟器

```bash
flutter run
```

#### 运行 Web (Chrome)

```bash
flutter run -d chrome
```

---

## 📂 项目结构

```
Pandora/
├── android/        # Android 平台相关代码
├── web/            # Web 平台构建相关文件
├── lib/            # Flutter 主代码 (Dart)
│   ├── main.dart   # 程序入口
│   └── widgets/    # 自定义组件
├── assets/         # 图片、字体等静态资源
├── pubspec.yaml    # 项目依赖配置
└── README.md
```


## 📄 License

MIT License

