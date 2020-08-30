---
title: 人脸识别SeetaFace6入门
date: 2020-08-30 19:38:41
tags:
- SeetaFace
- face detection
- face recognition
- linux
---

在今年三月中科视拓开放了最新的商业版本人脸识别算法。`SeetaFace6`是最新开放的商业版本，并且就在前几天，官方开放了`SeetaFace6`的源代码以及所使用的推理引擎`TenniS`。

最近我写一个玩具项目刚好用到了这个项目，总的来说，编译配置开源版本的`SeetaFace6`相对麻烦，故写本文记录如何使用`SeetaFace6`。

<!--more-->

#### 代码获取

首先，开源版本的代码地址在：[SeetaFace6](https://github.com/SeetaFace6Open/index)

执行操作`git clone --recursive https://github.com/SeetaFace6Open/index.git`获取项目的所有代码

这个仓库相当于一个索引，通过`submodule`的方式组合了`SeetaFace6`所包含的所有模块以及依赖库。

|          目录           |     功能     |
| :---------------------: | :----------: |
|  `FaceAntiSpoofingX6`   |   活体检测   |
|       `FaceBoxes`       |   人脸检测   |
|    `FaceRecognizer6`    |   人脸识别   |
|     `FaceTracker6`      |   人脸追踪   |
|      `Landmarker`       |  特征点提取  |
|    `PoseEstimator6`     |   姿态评估   |
|   `QualityAssessor3`    |   质量评估   |
|   `SeetaAgePredictor`   |   年龄检测   |
| `SeetaEyeStateDetector` | 眼睛状态检测 |
| `SeetaGenderPredictor`  |   性别检测   |
|   `SeetaMaskDetector`   |   口罩检测   |
|      `OpenRoleZoo`      | 常用操作集合 |
|    `SeetaAuthorize`     | 模型解析工程 |
|        `TenniS`         | 前向计算框架 |

#### 代码编译

根据官方文档，我们需要先编译三个基础库：`OpenRoleZoo`、`SeetaAuthorize`、`TenniS`。

先是`OpenRoleZoo`，这个库需要修改一下源代码才能成功编译：修改代码`OpenRoleZoo/include/orz/mem/pot.h`，在第9行`#include<memory>`后面插入一行`#include <functional>`补充所需要的头文件。然后就执行`cmake`指令并且编译安装。

这个模块所用到的配置选项有：`CMAKE_BUILD_TYPE`(设置`Release`就好了)、`ORZ_WITH_OPENSSL`(设置为`OFF`，官方的脚本内均为`OFF`)、`CMAKE_INSTALL_PREFIX`(设置为一个固定的目录，其它模块要用到)

然后是`SeetaAuthorize`和`TenniS`模块。这里`SeetaAuthorize`模块需要指定`PLATFORM`(`auto`或`x86`或`x64`)，否则在编译其它模块时会报错，同时需要指定`ORZ_ROOT_DIR`为上一步`OpenRoleZoo`的安装目录；至于`TenniS`模块，不同的平台，可以启用不同的优化选项，具体参考[TenniS](https://github.com/TenniS-Open/TenniS)

在编译完基础模块后，就可以按需编译自己所需要的其它模块了。

其它模块在配置时需要指定的选项有：`CMAKE_BUILD_TYPE`（默认`Release`即可）、`PLATFORM`（本地平台编译`auto`即可）、`SEETA_INSTALL_PREFIX`（不是所有的模块都支持，这里设置为前面的安装目录）、`ORZ_ROOT_PATH`（前面的安装目录）、`CMAKE_MODULE_PATH`（前面的安装目录`+/cmake`）、`SEETA_AUTHORIZE`（官方给的构建脚本是`OFF`，但是当后面那个设置为`ON`后会变成`ON`）、`SEETA_MODEL_ENCRYPT`（如果使用官方的模型就设置为`ON`）

需要说明的是，各个模块的维护者感觉不一样，每个项目的`CMakeLists.txt`的对同一个选项的处理逻辑不太相同。其中`QualityAssessor3`以及`FaceBoxes`模块会忽略你手动设置的`INSTALL_PREFIX`，而强制设置为`../build/`；同时，模块之间也有依赖关系，比如说`QualityAssessor3`依赖于`PoseEstimator6`等

为了方便，我写了一个脚本`build.sh`来配置编译`SeetaFace6`

这里我们默认`SeetaFace6`目录位于`./3rdparty/SeetaFace6`中，编译的文件置于`./build`目录下

(~~代码略丑、能用就好~~)

```bash
#!/usr/bin/env bash

# 环境变量准备
env_setup() {
  BUILD_HOME=$(
    cd "$(dirname "$0")" || exit
    pwd
  )

  BUILD_PATH_BASE="$BUILD_HOME"/build
  BUILD_PATH_SEETA="$BUILD_PATH_BASE"/SeetaFace_build
  INSTALL_PATH_SEETA="$BUILD_PATH_BASE"/SeetaFace
  SOURCE_PATH_SEETA="$BUILD_HOME"/3rdparty/SeetaFace6

  mkdir -p "$BUILD_PATH_BASE"
  mkdir -p "$BUILD_PATH_SEETA"
  mkdir -p "$INSTALL_PATH_SEETA"

  export BUILD_HOME
  export BUILD_PATH_BASE
  export BUILD_PATH_SEETA
  export INSTALL_PATH_SEETA
  export SOURCE_PATH_SEETA

  CORES="-j"$(grep -c "processor" </proc/cpuinfo)
  export CORES
}

build_seeta_OpenRoleZoo() {
  echo -e "\n>> Building OpenRoleZoo"
  mkdir -p "$BUILD_PATH_SEETA"/OpenRoleZoo
  cd "$BUILD_PATH_SEETA"/OpenRoleZoo || exit

  echo -e ">>> Fixing OpenRoleZoo"
  if grep -q "<functional>" "$SOURCE_PATH_SEETA"/OpenRoleZoo/include/orz/mem/pot.h; then
    echo -e ">>>> Already Fixed!"
  else
    sed -i '/<memory>/a\#include <functional>' "$SOURCE_PATH_SEETA"/OpenRoleZoo/include/orz/mem/pot.h
    echo ">>>> Fixed!"
  fi

  echo -e ">>> Configuring OpenRoleZoo"
  cmake "$SOURCE_PATH_SEETA"/OpenRoleZoo \
    -DCMAKE_BUILD_TYPE="Release" \
    -DORZ_WITH_OPENSSL=OFF \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH_SEETA" || exit

  echo -e "\n>>> Making OpenRoleZoo"
  make "$CORES" || exit
  make install || exit

  echo -e "\n>> OpenRoleZoo Built"
}

build_seeta_Authorize() {
  echo -e "\n>> Building SeetaAuthorize"
  mkdir -p "$BUILD_PATH_SEETA"/SeetaAuthorize
  cd "$BUILD_PATH_SEETA"/SeetaAuthorize || exit

  echo -e ">>> Configuring SeetaAuthorize"
  cmake "$SOURCE_PATH_SEETA"/SeetaAuthorize \
    -DCMAKE_BUILD_TYPE="Release" \
    -DPLATFORM="auto" \
    -DORZ_ROOT_DIR="$INSTALL_PATH_SEETA" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH_SEETA" || exit

  echo -e "\n>>> Making SeetaAuthorize"
  make "$CORES" || exit
  make install || exit

  echo -e "\n>> SeetaAuthorize Built"
}

build_seeta_TenniS() {
  echo -e "\n>> Building TenniS"
  mkdir -p "$BUILD_PATH_SEETA"/TenniS
  cd "$BUILD_PATH_SEETA"/TenniS || exit

  echo -e ">>> Configuring TenniS"
  
  # 这里我选用了Arm平台，其它平台根据文档修改
  cmake "$SOURCE_PATH_SEETA"/TenniS \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH_SEETA" \
    -DTS_USE_OPENMP=ON \
    -DTS_BUILD_TEST=OFF \
    -DTS_BUILD_TOOLS=OFF \
    -DTS_ON_ARM=ON || exit

  echo -e "\n>>> Making TenniS"
  make "$CORES" || exit
  make install || exit

  echo -e "\n>> TenniS Built"
}

build_seeta_module() {
  echo -e "\n>> Building $1"
  mkdir -p "$BUILD_PATH_SEETA"/"$1"
  cd "$BUILD_PATH_SEETA"/"$1" || exit

  echo -e ">>> Configuring $1"
  cmake "$SOURCE_PATH_SEETA"/"$1" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DPLATFORM="auto" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH_SEETA" \
    -DSEETA_INSTALL_PATH="$INSTALL_PATH_SEETA" \
    -DORZ_ROOT_DIR="$INSTALL_PATH_SEETA" \
    -DCMAKE_MODULE_PATH="$INSTALL_PATH_SEETA"/cmake \
    -DCONFIGURATION="Release" \
    -DSEETA_AUTHORIZE=OFF \
    -DSEETA_MODEL_ENCRYPT=ON || exit

  echo -e "\n>>> Making $1"
  make "$CORES" || exit
  make install || exit

  echo -e "\n>> $1 Built"
}

build_seeta() {
  echo -e "\n> Building SeetaFace"

  build_seeta_OpenRoleZoo
  build_seeta_Authorize
  build_seeta_TenniS
  
  # 需要注意的是如果是64位平台，部分.so文件会放置于/lib64目录下，而其它模块的cmake配置写的有问题，会搜索不到，需要手动复制到/lib目录下。（同时编译64位和32位时需要注意这个操作是有问题的）
  if [ -d "$INSTALL_PATH_SEETA"/lib64 ]; then
    cp -u "$INSTALL_PATH_SEETA"/lib64/* "$INSTALL_PATH_SEETA"/lib
  fi
  
  # 这里只编译了4个模块，按需增加
  build_seeta_module Landmarker
  build_seeta_module FaceRecognizer6
  build_seeta_module PoseEstimator6
  build_seeta_module QualityAssessor3

  # 前面说过了，QualityAssessor3等模块会忽略我们手动设定的INSTALL_PREFIX，我们手动移动合并一下文件
  cp -rfu "$SOURCE_PATH_SEETA"/build/* "$INSTALL_PATH_SEETA"
  rm -rf "$SOURCE_PATH_SEETA"/build
  
  # 一样的问题
  if [ -d "$INSTALL_PATH_SEETA"/lib64 ]; then
    cp -u "$INSTALL_PATH_SEETA"/lib64/* "$INSTALL_PATH_SEETA"/lib
  fi

}

echo "==========Start Building=========="
env_setup
echo "BUILD_HOME: $BUILD_HOME"
echo "Build Path: $BUILD_PATH_BASE"

build_seeta

echo "==========Build Finished!=========="
```

#### 代码使用

具体可以参考官方给出的文档使用：[文档](http://leanote.com/blog/post/5e7d6cecab64412ae60016ef)

有几点感觉要单独说一下的：

首先是一个常用的`hack`：将`cv::Mat`转换成`SeetaImageData`

```c++
// 代码来自官方文档
namespace seeta
{
    namespace cv
    {
        // using namespace ::cv;
        class ImageData : public SeetaImageData {
        public:
            ImageData( const ::cv::Mat &mat )
                : cv_mat( mat.clone() ) {
                this->width = cv_mat.cols;
                this->height = cv_mat.rows;
                this->channels = cv_mat.channels();
                this->data = cv_mat.data;
            }
        private:
            ::cv::Mat cv_mat;
        };
    }
}
```

然后是`ModelSetting`，在使用许多模块时要定义一个`ModelSetting`，否则无法使用

```c++
// 以FaceLandmarker为例
FaceLandmarker = new seeta::FaceLandmarker(
	seeta::ModelSetting("./data/SeetaFace/face_landmarker_pts5.csta"));
// 需要注意，QualityAssessor相对不同
QualityAssessor = new seeta::QualityAssessor();
QualityAssessor->add_rule(seeta::INTEGRITY);
QualityAssessor->add_rule(seeta::RESOLUTION);
QualityAssessor->add_rule(seeta::BRIGHTNESS);
QualityAssessor->add_rule(seeta::CLARITY);
```

最后，关于各个模块，遇到文档读不懂的时候，可以参考官方示例：[示例](https://github.com/SeetaFace6Open/index/tree/master/example/qt)

同时，必要时也得参考具体的源码，文档中所列举的函数在代码中没有完全实现，比如说许多的`_v2`的接口等。

