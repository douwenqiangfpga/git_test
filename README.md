# git_test

## 1. 项目说明
本项目为 FPGA/SPWM 工程，当前已完成最小仿真脚本化管理。

## 2. 目录结构
- `rtl/`：RTL 源码
- `tb/`：Testbench
- `ip/`：IP 文件及其必要实现文件
- `constr/`：约束文件
- `scripts/`：仿真脚本、环境配置、波形脚本
- `prj/`：IDE 生成工程目录，不纳入 Git 管理
- build/：PDS 实现流程输出目录（不纳入 Git）

## 3. 当前顶层关系
- DUT 顶层：`rtl/top.v`
- Testbench：`tb/tb_top.v`

模块关系如下：

- `tb_top`
  - `top`
    - `PLL_IP`
    - `led`
    - `spwm_single_top`
      - `spwm_deadtime_insert`
      - `spwm_sine_lut_256_u12`

## 4. 当前仿真方式
在 `scripts/` 目录下运行：

```bat
sim.bat
```

## 5. 实现流程

当前 Pango/PDS 实现流程脚本为：

- `scripts/pds_run.tcl`
- `scripts/pds_run.bat`

运行方式：

```bat
cd scripts
pds_run.bat
```

或在 `scripts/` 目录下执行

pds_shell -file ./pds_run.tcl