*&---------------------------------------------------------------------*
*& Report ZWORK19_002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZWORK19_002 MESSAGE-ID ZMED19.

INCLUDE ZWORK19_002_TOP.
INCLUDE ZWORK19_002_SCR.
INCLUDE ZWORK19_002_F01.
INCLUDE ZWORK19_002_PBO.
INCLUDE ZWORK19_002_PAI.

INITIALIZATION.
  PERFORM SET_INIT.

START-OF-SELECTION.
  PERFORM GET_DATA.

  IF p_date IS NOT INITIAL.
    CALL SCREEN 100.
  ELSE.
    MESSAGE I000.
    EXIT.
  ENDIF.
