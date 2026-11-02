# RV32I Multi-Cycle CPU with APB Bus

SystemVerilog로 설계한 **RISC-V RV32I 멀티사이클 CPU**와 **AMBA APB 버스 시스템**입니다.
CPU의 메모리 접근을 APB Requester가 APB 프로토콜로 변환하고, 주소 디코딩을 거쳐 BRAM·GPI·GPO 등 주변장치(Completer)와 통신합니다.
C 코드를 RV32I 기계어로 바꿔 실제로 실행하고, 그 결과가 APB 버스를 통해 BRAM에 저장되는 것까지 검증했습니다.

> 4인 팀 프로젝트 (2026.09)
> **담당: CPU SW 검증, APB Completer(BRAM, GPI, GPO) 설계**

## System Overview

![Block Diagram](docs/images/block_diagram.png)

### System Flow

위 블록 다이어그램의 왼쪽에서 오른쪽으로, 명령어 하나가 이렇게 처리됩니다.

1. **Instruction ROM (명령어 저장 메모리)**
   PC가 가리키는 주소의 명령어(`instr_code`)를 꺼냅니다. 명령어 메모리와 데이터 버스가 분리된 하버드 구조라서, 명령어 인출과 메모리·주변장치 접근이 서로 막지 않습니다.
2. **Control Unit (명령어 해석)**
   opcode를 해석하고 `FETCH → DECODE → EXECUTE → MEM → WB` FSM을 돌면서 단계마다 `pc_en`, `rf_we`, `alusrc_sel`, `alu_control`, `bus_we` 같은 제어 신호를 만듭니다. Load/Store가 아닌 명령어는 MEM 단계를 건너뜁니다.
3. **Datapath (실행 연산 장치)**
   레지스터 파일 읽기, 즉치값 생성, ALU 연산, 분기 판정, PC 갱신을 하고, 결과를 WB 단계에서 레지스터 파일에 씁니다.
4. **APB Requester (버스 프로토콜 변환)**
   Load/Store일 때 CPU의 `bus_addr`, `bus_wdata`, `transfer`, `bus_we`를 받아 `IDLE → SETUP → ACCESS` 순서의 APB 전송으로 바꿉니다. 주소 상위 4비트로 RAM과 주변장치를 구분하고, `PSEL0~6` 중 하나를 선택합니다.
5. **APB Completer (메모리 & 주변장치)**
   선택된 BRAM·GPI·GPO가 `PREADY`/`PRDATA`로 응답하면, Mux가 그 값만 CPU로 돌려줍니다. CPU는 `ready`를 받은 뒤 다음 단계로 넘어갑니다.

## 왜 멀티사이클인가

싱글사이클 CPU는 가장 긴 명령어(Load)의 지연을 기준으로 클럭 주기가 정해지기 때문에, 짧은 명령어일수록 시간이 낭비됩니다.
명령어 하나를 5단계로 나눠 각 단계의 전파 지연을 줄이고, 명령어 종류에 따라 필요한 단계만 거치도록 했습니다.

| State | 동작 |
|---|---|
| FETCH | PC 갱신, 명령어 인출 (`pc_en = 1`) |
| DECODE | 레지스터 파일 읽기, 명령어 해석 |
| EXECUTE | ALU 연산, 주소 계산, 분기 판정 |
| MEM | APB 버스를 통한 메모리/주변장치 읽기·쓰기 (Load/Store만) |
| WB | 레지스터 파일 쓰기 |

## 지원 명령어

| Type | 명령어 |
|---|---|
| R | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND |
| I | ADDI 등 산술/논리/시프트 즉치 연산, JALR |
| IL (Load) | LB, LH, LW, LBU, LHU |
| S (Store) | SB, SH, SW |
| B | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| U | LUI, AUIPC |
| J | JAL |

## 메모리 맵

| 주소 범위 | 영역 | 크기 |
|---|---|---|
| `0x1000_0000 ~ 0x1000_FFFF` | RAM (APB BRAM) | 64 KB |
| `0x1001_0000 ~ 0x1FFF_FFFF` | Reserved | |
| `0x2000_0000 ~ 0x2000_00FF` | GPI | 256 B |
| `0x2000_0100 ~ 0x2000_01FF` | GPO | 256 B |
| `0x2000_0200 ~ 0x2000_02FF` | GPIO | 256 B |
| `0x2000_0300 ~ 0x2000_03FF` | UART | 256 B |

APB Requester의 주소 디코더는 상위 4비트(`PADDR[31:28]`)로 RAM과 주변장치를 먼저 구분하고, 주변장치는 `PADDR[11:8]`로 `PSEL1~6`을 선택해 비교 로직을 단순화했습니다.

## APB Requester & Completer

- **Requester**: CPU 버스 신호(`bus_addr`, `bus_wdata`, `transfer`, `bus_we`)를 받아 `IDLE → SETUP → ACCESS` FSM으로 APB 전송을 수행하고, 다음 전송 전까지 주소·데이터를 유지합니다.
- **Mux**: 선택된 Completer의 `PREADY`/`PRDATA`만 CPU로 전달합니다.
- **BRAM Completer**: `itype`에 따라 byte/half/word 단위로 쓰고 읽습니다 (SB/SH/SW, LB/LH/LW/LBU/LHU).
- **GPI / GPO**: CTR 레지스터로 입출력을 활성화하고 IDR(스위치 입력) / ODR(LED 출력)로 데이터를 주고받습니다. LED 출력은 `CTR & ODR`입니다.

## 검증

### 1) SW 검증: C 코드 → 기계어 실행

아래 C 코드를 RV32I 어셈블리와 기계어로 변환해 Instruction ROM(`rtl/rom_code_ex1.mem`)에 넣고 실행했습니다.

<img src="docs/images/c_code/image1.png" width="380">

`jal`(함수 호출), `bge`(루프 조건 분기), `lw → addi → sw`(`a = a + 1`)의 동작을 PC, 즉치값, ALU, 레지스터 파일, APB 신호 파형으로 단계별로 확인했습니다.
최종적으로 **sum = 55**가 APB 버스를 통해 BRAM(`PADDR = 488`, `dmem[122]`)에 저장되는 것을 확인했습니다.

![sum=55 결과](docs/images/apb_sw_verification/waveform/result/sum55_bram_requester.png)

명령어별 파형은 [`docs/images/apb_sw_verification/waveform`](docs/images/apb_sw_verification/waveform)에 있습니다.

### 2) UVM 검증 (팀원 담당)

- R/I 타입 19개 명령어를 대상으로 랜덤 시퀀스 생성, 각 명령어 실행 전 레지스터 초기화
- 모니터가 매 클럭 상승 엣지에서 `rf_we`, `alusrc_sel`, `alu_control` 등 제어 신호를 확인해 PASS/FAIL 판단
- **pass count 541,489 (예상값과 일치), 계획한 coverage 100% 달성**

### 3) 개별 과제: R/S-type 검증

싱글사이클 CPU에서 R-type 명령어의 일반 케이스와 엣지 케이스(음수 SRL/SRA, signed/unsigned 비교 SLT/SLTU), S-type(SB/SH/SW)의 주소-메모리 매핑을 검증한 보고서입니다. → [`docs/HW16_R-S-type_report.pdf`](docs/HW16_R-S-type_report.pdf)

## 트러블슈팅

**현상**: 시뮬레이션에서 결과 값이 기대보다 한 클럭 어긋나게 관측됨
**원인**: 결과 값을 클럭 상승 엣지 시점(1 step)에서 그대로 샘플링해, 레지스터에 반영되기 전·후 값이 섞여 보임
**해결**: 상승 엣지 직후(1ns 뒤)에 값을 확인하도록 샘플링 시점을 조정해 올바른 결과를 확인

## 디렉터리 구조

```
rv32i-cpu
├── rtl/                     # 최종 설계 (멀티사이클 CPU + APB)
│   ├── rv32i_top.sv         # Top: ROM + CPU + APB Requester + BRAM
│   ├── control_unit.sv      # 멀티사이클 FSM, 제어 신호 생성
│   ├── datapath.sv          # PC, 레지스터 파일, ALU, 즉치 생성기
│   ├── instruction_rom.sv
│   ├── apb_requester.sv     # APB Requester, 주소 디코더, Mux
│   ├── apb_bram.sv          # APB BRAM Completer
│   ├── pkg/rv32i_pkg.sv     # opcode / 명령어 / state enum
│   └── *.mem                # 실행할 기계어
├── tb/tb_rv32i.sv
├── history/
│   ├── single_cycle/        # 싱글사이클 RV32I (이전 단계)
│   └── multi_cycle_draft/   # 멀티사이클 초기 버전
├── docs/
│   ├── RV32I_CPU_APB_final_presentation.pdf
│   ├── HW16_R-S-type_report.pdf
│   └── images/
├── Makefile
└── pkg.f
```

## 시뮬레이션

Synopsys VCS + Verdi 환경 기준입니다.

```bash
make run     # 컴파일
make simv    # 시뮬레이션 실행 (wave.fsdb 생성)
make verdi   # 파형 확인
make clean
```

## 발표 자료

전체 설계 및 검증 과정은 [최종 발표 자료(PDF)](docs/RV32I_CPU_APB_final_presentation.pdf)에 정리되어 있습니다.

## 개발 환경

SystemVerilog, UVM, Synopsys VCS / Verdi
