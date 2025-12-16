*&---------------------------------------------------------------------*
*&  Include           ZWORK19_002_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_DATA .
  SELECT * FROM ZTCURR19 INTO TABLE GT_WORK
    WHERE GDATU = P_DATE.

  IF GT_WORK IS INITIAL.
    MESSAGE '조회조건이 잘못되었습니다.' TYPE 'E'.
    STOP.
  ENDIF.

  LOOP AT GT_WORK INTO GS_WORK.
    GS_WORK-CRNAME = SY-UNAME.
    GS_WORK-CRDATE = SY-DATUM.
    MODIFY GT_WORK FROM GS_WORK.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FIELD_CATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FIELD_CATALOG .
  CLEAR : GS_FIELDCAT, GT_FIELDCAT.
  GS_FIELDCAT-COL_POS = 1.
  GS_FIELDCAT-FIELDNAME = 'KURST'.
  GS_FIELDCAT-COLTEXT = '환율유형'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 2.
  GS_FIELDCAT-FIELDNAME = 'FCURR'.
  GS_FIELDCAT-COLTEXT = '소스통화'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 3.
  GS_FIELDCAT-FIELDNAME = 'TCURR'.
  GS_FIELDCAT-COLTEXT = '대상통화'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 4.
  GS_FIELDCAT-FIELDNAME = 'GDATU'.
  GS_FIELDCAT-COLTEXT = '효력시작'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 5.
  GS_FIELDCAT-FIELDNAME = 'UKURS'.
  GS_FIELDCAT-COLTEXT = '환율'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 6.
  GS_FIELDCAT-FIELDNAME = 'FFACT'.
  GS_FIELDCAT-COLTEXT = '원시통화단위비율'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 7.
  GS_FIELDCAT-FIELDNAME = 'TFACT'.
  GS_FIELDCAT-COLTEXT = '대상통화단위비율'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 8.
  GS_FIELDCAT-FIELDNAME = 'CRNAME'.
  GS_FIELDCAT-COLTEXT = '입력자'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

  CLEAR : GS_FIELDCAT.
  GS_FIELDCAT-COL_POS = 9.
  GS_FIELDCAT-FIELDNAME = 'CRDATE'.
  GS_FIELDCAT-COLTEXT = '입력일'.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_OBJECT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CREATE_OBJECT .
  CREATE OBJECT GC_CUSTOM
    EXPORTING
      CONTAINER_NAME              = 'CON1'.
  CREATE OBJECT GC_GRID
    EXPORTING I_PARENT = GC_CUSTOM.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CALL_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CALL_ALV .
  PERFORM ALV_DISPLAY.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ALV_DISPLAY .
  CALL METHOD GC_GRID->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING

      IS_LAYOUT                     = GS_LAYOUT

    CHANGING
      IT_OUTTAB                     = GT_WORK
      IT_FIELDCATALOG               = GT_FIELDCAT
      IT_SORT                       = GT_SORT.
ENDFORM.

FORM DOWNLOAD_PDF.
  DATA : lv_ok TYPE abap_bool,
         lv_rc TYPE I.

  " 0) 프론트 GUI 보장
  CALL FUNCTION 'GUI_IS_AVAILABLE'
    IMPORTING
      return = lv_ok.

  IF lv_ok IS INITIAL.
    MESSAGE '프론트 GUI 환경에서만 PDF 저장이 가능합니다.' TYPE 'E'.
  ENDIF.

  " 1) 디렉토리 선택 (없으면 TEMP)
  PERFORM pick_dir CHANGING gv_dir.

  " 2) 템플릿 내려받기 (네가 이미 가진 DOWNLOAD_TEMPLATE 로직을 호출)
  "    예: SMW0의 ZFX_TEMPLATE_XLSX를 gv_xlsx 경로에 떨구기
  gv_xlsx = gv_dir && '\ALV_EXPORT_' && sy-datum && '_' && sy-uzeit && '.xlsx'.
  PERFORM z19_download_template USING gv_xlsx.  " <- 네가 가진 루틴명에 맞춰 수정

  " 3) 엑셀 열고 데이터 쓰기
  PERFORM z19_open_excel_template USING gv_xlsx.
  PERFORM z19_fill_excel_from_alv.  " GT_WORK -> 엑셀 시트에 기입

  " 4) PDF 페이지 설정 + PDF 내보내기
  PERFORM z19_setup_pages.
  gv_pdf = gv_dir && '\ALV_' && sy-datum && '_' && sy-uzeit && '.pdf'.
  PERFORM z19_export_pdf USING gv_pdf.

  " 5) 닫기/정리 + 임시 XLSX 삭제
  PERFORM z19_excel_close.
  CALL METHOD cl_gui_frontend_services=>file_delete
    EXPORTING
      filename = gv_xlsx
    CHANGING
      rc = lv_rc
    EXCEPTIONS
      file_delete_failed = 1
      cntl_error = 2
      error_no_gui = 3
      not_supported_by_gui = 4
      wrong_parameter = 5
      OTHERS = 6.

  MESSAGE |PDF 저장 완료: { gv_pdf }| TYPE 'S'.
ENDFORM.

FORM pick_dir CHANGING pv_dir TYPE string.

  IF pv_dir IS INITIAL.
    cl_gui_frontend_services=>directory_browse(
      EXPORTING window_title    = 'PDF 저장 폴더 선택'
      CHANGING  selected_folder = pv_dir ).

    IF pv_dir IS INITIAL.
      cl_gui_frontend_services=>get_temp_directory(
        CHANGING temp_dir = pv_dir ).
    ENDIF.
  ENDIF.

ENDFORM.


FORM z19_fill_excel_from_alv.
  DATA: lo_cell TYPE ole2_object.
  DATA: lv_row TYPE i VALUE 2.

  DATA : lv_kurst TYPE string,
         lv_gdatu TYPE string,
         lv_fcurr TYPE string,
         lv_tcurr TYPE string,
         lv_ukurs TYPE string,
         lv_ffact TYPE string,
         lv_tfact TYPE string,
         lv_crname TYPE string,
         lv_crdate TYPE string.

  " 본문
  LOOP AT gt_work INTO gs_work.
    lv_row = lv_row + 1.

    lv_kurst = |{ gs_work-kurst }|.
    lv_fcurr = |{ gs_work-fcurr }|.
    lv_tcurr = |{ gs_work-tcurr }|.
    lv_gdatu = |{ gs_work-gdatu }|.
    lv_ukurs = |{ gs_work-ukurs }|.
    lv_ffact = |{ gs_work-ffact }|.
    lv_tfact = |{ gs_work-tfact }|.
    lv_crname = |{ gs_work-crname }|.
    IF gs_work-crdate IS INITIAL.
      CLEAR lv_crdate.
    ELSE.
      lv_crdate = |{ gs_work-crdate }|.
    ENDIF.

    PERFORM z19_put_cell USING lv_row 2 lv_kurst.
    PERFORM z19_put_cell USING lv_row 3 lv_fcurr.
    PERFORM z19_put_cell USING lv_row 4 lv_tcurr.
    PERFORM z19_put_cell USING lv_row 5 lv_gdatu.
    PERFORM z19_put_cell USING lv_row 6 lv_ukurs.
    PERFORM z19_put_cell USING lv_row 7 lv_ffact.
    PERFORM z19_put_cell USING lv_row 8 lv_tfact.
    PERFORM z19_put_cell USING lv_row 9 lv_crname.
    PERFORM z19_put_cell USING lv_row 10 lv_crdate.

  ENDLOOP.

  " UsedRange
  GET PROPERTY OF g_worksheet 'UsedRange' = g_usedrange.

  DATA lo_columns TYPE ole2_object.
  GET PROPERTY OF g_usedrange 'Columns' = lo_columns.
  CALL METHOD OF lo_columns 'AutoFit'.
  FREE OBJECT lo_columns.
ENDFORM.


FORM z19_put_cell USING pv_row TYPE i pv_col TYPE i pv_val TYPE any.
  DATA lo_cell TYPE ole2_object.
  CALL METHOD OF g_worksheet 'Cells' = lo_cell
    EXPORTING #1 = pv_row #2 = pv_col.
  SET PROPERTY OF lo_cell 'Value' = pv_val.
  FREE OBJECT lo_cell.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_SCREEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SET_SCREEN .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ALV_LAYOUT .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SET_INIT .

ENDFORM.

*---------------------------------------------------------------------*
*  템플릿 파일(WWWData: ZFX_TEMPLATE_XLSX) 내려받기
*---------------------------------------------------------------------*
FORM z19_download_template USING pv_xlsx TYPE string.
  DATA: ls_key TYPE wwwdatatab,
        lv_dest TYPE rlgrap-filename.

  lv_dest = pv_xlsx.

  SELECT SINGLE *
    FROM wwwdata
    INTO CORRESPONDING FIELDS OF ls_key
    WHERE relid = 'MI'
      AND objid = 'ZFX_TEMPLATE_XLSX'
      AND srtf2 = 0.

  IF sy-subrc <> 0.
    MESSAGE 'SMW0 오브젝트(ZFX_TEMPLATE_XLSX) 없음' TYPE 'E'.
    EXIT.
  ENDIF.

  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = ls_key
      destination = lv_dest.
ENDFORM.

*---------------------------------------------------------------------*
*  Excel 템플릿 열기
*---------------------------------------------------------------------*
FORM z19_open_excel_template USING pv_xlsx TYPE string.
  DATA: lo_wbooks TYPE ole2_object.

  CREATE OBJECT g_excel 'Excel.Application'.
  IF sy-subrc <> 0.
    MESSAGE 'Excel OLE 생성 실패' TYPE 'E'.
  ENDIF.

  SET PROPERTY OF g_excel 'Visible' = 0.  " 백그라운드

  " Workbooks 컬렉션 받기
  CALL METHOD OF g_excel 'Workbooks' = lo_wbooks.

  " Open의 반환을 g_workbook으로!
  CALL METHOD OF lo_wbooks 'Open' = g_workbook
    EXPORTING #1 = pv_xlsx.

  " 첫번째 시트 취득
  CALL METHOD OF g_workbook 'Worksheets' = g_worksheet
    EXPORTING #1 = 1.

  FREE OBJECT lo_wbooks.
ENDFORM.

*---------------------------------------------------------------------*
*  페이지 설정 (여백/가로인쇄 등)
*---------------------------------------------------------------------*
FORM z19_setup_pages.
  DATA: lo_pagesetup TYPE ole2_object.
  GET PROPERTY OF g_worksheet 'PageSetup' = lo_pagesetup.
  " A4, 가로
  SET PROPERTY OF lo_pagesetup 'Orientation' = 2.   " xlLandscape
  SET PROPERTY OF lo_pagesetup 'PaperSize'   = 9.   " xlPaperA4

  SET PROPERTY OF lo_pagesetup 'CenterHorizontally' = 1.
  SET PROPERTY OF lo_pagesetup 'CenterVertically'   = 1.
  FREE OBJECT lo_pagesetup.
ENDFORM.

*---------------------------------------------------------------------*
*  PDF로 내보내기
*---------------------------------------------------------------------*
FORM z19_export_pdf USING pv_pdf TYPE string.
  " ExportAsFixedFormat(Type:=0,xlTypePDF)
  CALL METHOD OF g_worksheet 'ExportAsFixedFormat'
    EXPORTING
      #1 = 0        " Type: 0 = PDF
      #2 = pv_pdf.  " Filename
ENDFORM.

*---------------------------------------------------------------------*
*  Excel 종료/자원 정리
*---------------------------------------------------------------------*
FORM z19_excel_close.
  IF g_workbook-HANDLE <> 0.
    CALL METHOD OF g_workbook 'Close' EXPORTING #1 = 0.
  ENDIF.
  IF g_excel-HANDLE <> 0.
    CALL METHOD OF g_excel 'Quit'.
  ENDIF.

  FREE OBJECT g_usedrange.
  FREE OBJECT g_worksheet.
  FREE OBJECT g_workbook.
  FREE OBJECT g_excel.
ENDFORM.
