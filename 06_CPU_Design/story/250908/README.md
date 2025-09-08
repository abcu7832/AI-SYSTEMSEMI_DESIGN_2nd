# 강의 내용

# 🖥️ Display Timing 정리 (Front Porch / Sync / Back Porch / Horizontal & Vertical)

디지털 디스플레이 시스템(VGA, HDMI 등)에서는 화면을 구성하기 위해 **수평(Horizontal)** 및 **수직(Vertical)** 방향의 타이밍이 필수적입니다.  
이를 구성하는 기본 요소인 **Front Porch**, **Sync Pulse**, **Back Porch**, **Active Video**에 대해 설명합니다.

---

## 📘 1. 디스플레이 타이밍 개요

디스플레이는 한 프레임을 출력하기 위해 수많은 **라인(Line)**과 **픽셀(Pixel)**을 그립니다.  
각 줄과 프레임 사이에는 **동기화 신호(Sync Pulse)**와 **여유 구간(Porch)**이 존재하여,  
정확한 화면 출력과 디스플레이 장치의 안정적인 처리를 돕습니다.

---

## 🧱 2. 주요 용어 설명

![250908_VGA](/images/250908_VGA.png)

---

### VGA 640*480 -> 디스플레이 영역(porch와 sync 구간 제외) / 합치면 horizontal: 800 pixels, vertical: 525 lines

| 용어              | 설명 |
|-------------------|------|
| **Front Porch**   | 화면을 그리기 *전*의 짧은 여유 시간 |
| **Sync Pulse**    | 디스플레이에 “줄/프레임이 끝났다”는 신호를 보내는 구간 |
| **Back Porch**    | 동기 신호 이후 *본격적인 픽셀 데이터 전*의 여유 시간 |
| **Active Video**  | 실제로 화면에 **표시되는 유효한 픽셀** 데이터 |
| **Horizontal Timing** | 한 줄(Line)을 출력하기 위한 전체 시간 구성 |
| **Vertical Timing**   | 한 프레임(Frame)을 출력하기 위한 전체 시간 구성 |

---
### Standard Timing

http://tinyvga.com/vga-timing

## ⏱ 3. 수평 타이밍 (Horizontal Timing)

하나의 라인(Line)을 출력하는 전체 타이밍 구조는 다음과 같습니다:

←------------ One Line ------------→

[ Front Porch ] → [ Sync Pulse ] → [ Back Porch ] → [ Active Video ]


### ✅ VGA 640x480 @ 60Hz 기준 수평 타이밍

| 구간         | 클럭 수 (픽셀 기준) |
|--------------|---------------------|
| Front Porch  | 16 px               |
| Sync Pulse   | 96 px               |
| Back Porch   | 48 px               |
| Active Video | 640 px              |
| **총합**     | **800 px**          |

---

## ⬇️ 4. 수직 타이밍 (Vertical Timing)

하나의 **프레임(Frame)**을 구성하기 위한 줄(Line) 단위 타이밍:


### ✅ VGA 640x480 @ 60Hz 기준 수직 타이밍

| 구간         | 줄 수 (Line 기준) |
|--------------|------------------|
| Front Porch  | 10 lines         |
| Sync Pulse   | 2 lines          |
| Back Porch   | 33 lines         |
| Active Video | 480 lines        |
| **총합**     | **525 lines**     |

---

## 📊 5. 전체 타이밍 요약

| 구분         | 수평 타이밍 (px) | 수직 타이밍 (줄) |
|--------------|------------------|------------------|
| Front Porch  | 16               | 10               |
| Sync Pulse   | 96               | 2                |
| Back Porch   | 48               | 33               |
| Active Video | 640              | 480              |
| **총합**     | **800**          | **525**          |

---

### <주파수 계산>

ex) 1초 -> 800px * 525 line * 60 frame = 25.2MHz

pixel을 기준으로 계산!!

---

## 🤔 6. 왜 이런 타이밍이 필요한가?

- 디스플레이 장치는 픽셀을 출력하기 전에 **준비 시간이 필요**합니다.
- **Sync Pulse**를 통해 **줄의 시작/끝**, **프레임의 시작/끝**을 정확히 알립니다.
- **Porch 구간**은 장치가 데이터를 안정적으로 처리하도록 **여유 시간을 제공**합니다.

---

## 🧾 7. 타이밍 구조 다이어그램

```text
[ Horizontal Timing ]
|<--Front-->|<--Sync-->|<--Back-->|<--Active Video-->|
    16 px      96 px      48 px         640 px

[ Vertical Timing ]
|<--Front-->|<--Sync-->|<--Back-->|<--Active Video-->|
    10 lines    2 lines    33 lines      480 lines
```

## ✅ 8. 핵심 요약

Front Porch: 다음 Sync 전에 잠깐 대기 (줄/프레임 시작 전)

Sync Pulse: “줄/프레임 시작”을 알리는 동기 신호

Back Porch: Sync 이후 데이터 출력 전의 안정 대기

Active Video: 실제로 디스플레이에 보여지는 픽셀들
