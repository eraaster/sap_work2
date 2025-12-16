*&---------------------------------------------------------------------*
*&  Include           ZWORK19_0002_TOP
*&---------------------------------------------------------------------*

TABLES : ZTCURR19.

TYPE-POOLS: OLE2.

DATA : OK_CODE TYPE SY-UCOMM.

DATA: gt_work TYPE STANDARD TABLE OF ztcurr19,
      gs_work LIKE LINE OF gt_work.

" LVC ALV
DATA: gs_layout   TYPE lvc_s_layo,
      gt_fieldcat TYPE lvc_t_fcat,
      gs_fieldcat TYPE lvc_s_fcat,
      gt_sort     TYPE lvc_t_sort.

" 컨테이너/그리드
DATA: gc_custom TYPE REF TO cl_gui_custom_container,
      gc_grid   TYPE REF TO cl_gui_alv_grid.

DATA: gv_dir  TYPE string,
      gv_xlsx TYPE string,
      gv_pdf  TYPE string.

" OLE 객체 전역
DATA: g_excel      TYPE ole2_object,
      g_workbooks  TYPE ole2_object,
      g_workbook   TYPE ole2_object,
      g_worksheet  TYPE ole2_object,
      g_usedrange  TYPE ole2_object,
      g_pagesetup  TYPE ole2_object.
