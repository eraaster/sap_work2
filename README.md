# ZWORK19_002 – 환율 조회 및 PDF 출력 프로그램

## 📘 프로그램 개요
본 프로그램은 SAP ABAP 기반의 환율 조회 프로그램으로,  
기준일자를 조건으로 환율 데이터를 조회하여 ALV Grid로 출력하고  
조회된 결과를 Excel 템플릿을 거쳐 PDF 파일로 저장하는 기능을 제공한다.

환율 데이터는 Custom Table(ZTCURR19)에서 조회되며,  
ALV 화면에서 확인한 데이터를 문서(PDF) 형태로 보관할 수 있도록 구현하였다.

## 🎯 개발 목적
- Selection Screen 기반 데이터 조회 로직 구현
- ALV Grid를 활용한 조회 결과 시각화
- SMW0 템플릿 기반 Excel/PDF 출력 기능 구현
- SAP 프론트엔드(OLE) 연동 실습

## 🛠 개발 환경
- SAP NetWeaver AS ABAP
- ABAP Report
- ALV Grid (CL_GUI_ALV_GRID)
- OLE Automation (Excel)
- Custom Message Class (ZMED19)

## 📂 프로그램 구조
```text
ZWORK19_002
├─ ZWORK19_002_TOP   # 전역 타입, 상수, 데이터 선언
├─ ZWORK19_002_SCR   # Selection Screen (조회 조건)
├─ ZWORK19_002_F01   # 조회, ALV, PDF 출력 로직
├─ ZWORK19_002_PBO   # 화면 PBO
└─ ZWORK19_002_PAI   # 화면 PAI
