

## 1.目录结构

本项目为 FPGA / SPWM 工程，当前已完成以下内容：

- 工程已纳入 Git 管理
- 已推送到远程 GitHub 仓库
- ModelSim 仿真流程已脚本化
- Pango / PDS 实现流程已脚本化
- 已验证可生成 bit 流文件
- 实现输出目录已整理到 `build/` 下

当前工程管理思路为：

- `rtl/`、`tb/`、`ip/`、`constr/`、`scripts/` 属于工程输入，纳入 Git
- `build/`、仿真库、日志、临时文件属于工具生成物，不纳入 Git

---

## 2. 目录结构

```text
git_test/
├─ rtl/          # RTL 源码
├─ tb/           # Testbench
├─ ip/           # IP 文件及必要实现文件
├─ constr/       # 约束文件
├─ scripts/      # 仿真脚本、实现脚本、环境配置
├─ build/        # PDS 实现输出目录（不纳入 Git）
├─ README.md
└─ .gitignore
```

目录说明：

- `rtl/`：顶层设计及功能模块源码
- `tb/`：仿真 testbench
- `ip/`：IP 核心文件、配置文件及必要实现文件
- `constr/`：时序 / 管脚约束文件
- `scripts/`：仿真与实现入口脚本
- `build/`：PDS flow 运行后生成的工程数据库、报告、bit 流等输出目录
- `prj/`：IDE 手工工程目录，不作为当前主流程依赖

------

## 3. 当前顶层关系

当前工程顶层关系如下：

```text
tb_top
└─ top
   ├─ PLL_IP
   ├─ led
   └─ spwm_single_top
      ├─ spwm_deadtime_insert
      └─ spwm_sine_lut_256_u12
```

当前主要入口：

- Testbench：`tb/tb_top.v`
- DUT Top：`rtl/top.v`

------

## 4. 目标器件

当前目标器件配置为：

- Family：`Logos`
- Device：`PGL50G`
- Package：`FBG484`
- Speed Grade：`-6`

------

## 5. 仿真流程

当前仿真主脚本：

- `scripts/run_sim.tcl`
- `scripts/sim.bat`
- `scripts/wave.do`

### 仿真运行方式

进入 `scripts/` 目录后运行：

```bat
sim.bat
```

### 仿真流程说明

`sim.bat` 会调用 ModelSim，并执行：

- `run_sim.tcl`
- 编译 IP / RTL / TB 文件
- 映射厂商仿真库 `usim`
- 启动 testbench
- 自动加载 `wave.do`
- 自动运行仿真

### 当前仿真依赖

当前最小仿真依赖包括：

- `rtl/led.v`
- `rtl/spwm_deadtime_insert.v`
- `rtl/spwm_single_top.v`
- `rtl/top.v`
- `tb/tb_top.v`
- `ip/PLL_IP/PLL_IP.v`
- `ip/spwm_sine_lut_256_u12/spwm_sine_lut_256_u12.v`
- `ip/spwm_sine_lut_256_u12/rtl/ipml_rom_v1_7_spwm_sine_lut_256_u12.v`
- `ip/spwm_sine_lut_256_u12/rtl/ipml_spram_v1_7_spwm_sine_lut_256_u12.v`
- `ip/spwm_sine_lut_256_u12/rtl/spwm_sine_lut_256_u12_init_param.v`

### 仿真环境说明

仿真依赖：

- ModelSim
- 厂商仿真库 `usim`

相关配置文件：

- `scripts/env.bat`
- `scripts/env.tcl`

如果更换电脑，优先检查这两个文件中的工具路径和库路径。

------

## 6. 实现流程

当前 Pango / PDS 实现主脚本：

- `scripts/pds_run.tcl`
- `scripts/pds_run.bat`

### 实现运行方式

进入 `scripts/` 目录后运行：

```bat
pds_run.bat
```

也可以手工执行：

```bat
pds_shell -file ./pds_run.tcl
```

### 当前实现流程说明

`pds_run.tcl` 当前会完成以下步骤：

1. 添加 RTL 设计文件
2. 添加 IP 设计文件
3. 添加约束文件
4. 设置目标器件
5. 执行 `compile`
6. 执行 `synthesize -ads`
7. 执行 `dev_map`
8. 执行 `pnr`
9. 执行 `report_timing`
10. 执行 `gen_bit_stream`

### 当前实现输入

RTL 输入：

- `rtl/led.v`
- `rtl/spwm_deadtime_insert.v`
- `rtl/spwm_single_top.v`
- `rtl/top.v`

IP 输入：

- `ip/PLL_IP/PLL_IP.idf`
- `ip/spwm_sine_lut_256_u12/spwm_sine_lut_256_u12.idf`

约束输入：

- `constr/spwm.fdc`

------

## 7. 输出目录

PDS 实现输出默认生成在：

- `build/pds/`

该目录中通常包括：

- flow 工程数据库
- `compile/`
- `synthesize/`
- `device_map/`
- `place_route/`
- `generate_bitstream/`
- `report_timing/`
- 其它日志和中间文件

说明：

- `build/` 为工具生成物目录
- `build/` 不纳入 Git 管理

------

## 8. IP 说明

当前工程主要使用以下 IP：

### 1. `ip/PLL_IP/`

用途：

- 时钟生成

当前保留的核心文件包括：

- `PLL_IP.v`
- `PLL_IP.idf`

### 2. `ip/spwm_sine_lut_256_u12/`

用途：

- SPWM 正弦查找表

当前保留的核心文件包括：

- `spwm_sine_lut_256_u12.v`
- `spwm_sine_lut_256_u12.idf`
- `rtl/ipml_rom_v1_7_spwm_sine_lut_256_u12.v`
- `rtl/ipml_spram_v1_7_spwm_sine_lut_256_u12.v`
- `rtl/spwm_sine_lut_256_u12_init_param.v`
- 初始化数据文件

说明：

- IP 模板文件、示例 testbench、工具生成痕迹文件已从 Git 管理中剔除
- 当前 Git 中保留的是工程真正依赖的 IP 输入文件

------

## 9. Git 管理说明

当前纳入 Git 管理的内容包括：

- RTL 源码
- Testbench
- IP 核心文件
- 约束文件
- 仿真脚本
- 实现脚本
- README
- `.gitignore`

当前不纳入 Git 管理的内容包括：

- `build/`
- 仿真 `work/`
- `sim.log`
- `transcript`
- `*.wlf`
- `modelsim.ini`
- IDE 生成目录
- 工具日志、中间数据库、实现输出目录

核心原则：

> Git 管工程输入，不管工具生成结果。

------

## 10. 日常使用

### 1）仿真

进入 `scripts/` 目录后运行：

```bat
sim.bat
```

作用：

- 启动 ModelSim
- 执行 `run_sim.tcl`
- 编译仿真相关文件
- 加载 `wave.do`
- 运行 testbench

### 2）实现

进入 `scripts/` 目录后运行：

```bat
pds_run.bat
```

作用：

- 调用 `pds_shell`
- 执行 `pds_run.tcl`
- 完成实现流程
- 生成 bit 流文件

### 3）输出

PDS 实现输出默认在：

- `build/pds/`

### 4）环境配置

需要优先检查：

- `scripts/env.bat`
- `scripts/env.tcl`

其中：

- `env.bat`：配置本机工具路径
- `env.tcl`：配置仿真相关路径

如果更换电脑，优先修改这两个文件。

### 5）日常提交流程

日常开发后建议按下面流程操作：

```bash
git status
git add .
git commit -m "说明本次修改内容"
git push
```

建议提交前至少完成：

1. 仿真检查
2. 实现流程检查
3. 确认输出正常

------

## 11. 当前脚本入口

当前建议使用的正式入口如下：

### 仿真入口

- `scripts/sim.bat`

### 实现入口

- `scripts/pds_run.bat`

说明：

- `create_project.tcl` 目前不作为主流程脚本
- 当前主流程以 `run_sim.tcl` 和 `pds_run.tcl` 为准

------

## 12. 后续计划

后续可继续推进的方向包括：

- 继续优化 `wave.do`
- 增强 testbench 覆盖范围
- 继续整理实现日志与报告输出
- 规范 build 清理流程
- 逐步增强脚本说明和工程交接文档

```
替换完后建议提交一次：

```bash
git add README.md
git commit -m "docs: replace README with full project usage guide"
git push
```