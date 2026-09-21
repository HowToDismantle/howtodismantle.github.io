FUNCTION z_pb_doc_create_base64.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_DOKOB) LIKE  DRAD-DOKOB DEFAULT 'MARA'
*"     VALUE(IV_OBJKY) LIKE  DRAD-OBJKY
*"     VALUE(IV_DOKAR) TYPE  DOKAR DEFAULT 'DRW'
*"     VALUE(IV_DESCRIPTION) LIKE  BAPI_DOC_DRAW2-DESCRIPTION OPTIONAL
*"     VALUE(IV_FILENAME) LIKE  CVAPI_DOC_FILE-FILENAME
*"     VALUE(IV_DAPPL) LIKE  CVAPI_DOC_FILE-DAPPL OPTIONAL
*"     VALUE(IV_STORAGE_CAT) LIKE  CVAPI_DOC_FILE-STORAGE_CAT DEFAULT
*"       'DMS_C1_ST'
*"  EXPORTING
*"     VALUE(EV_DOKNR) TYPE  DOKNR
*"     VALUE(EV_DOKVR) TYPE  DOKVR
*"     VALUE(EV_DOKTL) TYPE  DOKTL_D
*"  TABLES
*"      IT_BASE64 STRUCTURE  SOLI
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  DATA: lv_b64      TYPE string,
        lv_name     TYPE string,
        lv_ext      TYPE string,
        lv_xstr     TYPE xstring,
        lv_size     TYPE i,
        lv_off      TYPE i,
        lv_len      TYPE i,
        lv_cnt      TYPE i,
        lv_objky    TYPE drad-objky,
        lv_matnr    TYPE matnr,
        lv_dappl    TYPE cvapi_doc_file-dappl,
        lv_descr    TYPE bapi_doc_draw2-description,
        ls_docdata  TYPE bapi_doc_draw2,
        ls_return   TYPE bapiret2,
        lt_objlinks TYPE STANDARD TABLE OF bapi_doc_drad,
        ls_objlink  TYPE bapi_doc_drad,
        lt_files    TYPE STANDARD TABLE OF cvapi_doc_file,
        ls_file     TYPE cvapi_doc_file,
        lt_drao     TYPE STANDARD TABLE OF drao,
        ls_drao     TYPE drao,
        ls_api      TYPE cvapi_api_control,
        ls_msg      TYPE messages.

  CLEAR: ev_doknr, ev_dokvr, ev_doktl.
  REFRESH et_return.

* 1) Glue the 255 character chunks together and decode the Base64 string.
  CONCATENATE LINES OF it_base64 INTO lv_b64.
  IF lv_b64 IS NOT INITIAL.
    lv_xstr = cl_http_utility=>decode_x_base64( lv_b64 ).
  ENDIF.
  lv_size = xstrlen( lv_xstr ).
  IF lv_size = 0.
*   Nothing to upload - leave before anything is created in the DMS.
    ls_return-type    = 'E'.
    ls_return-message = 'No document content received (IT_BASE64 empty or invalid)'.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

* 2) The material number is the only object key with a conversion exit,
*    so purely numeric material numbers have to be padded first.
  lv_objky = iv_objky.
  IF iv_dokob = 'MARA'.
    lv_matnr = iv_objky.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        input  = lv_matnr
      IMPORTING
        output = lv_matnr.
    lv_objky = lv_matnr.
  ENDIF.

* 3) Workstation application (PDF, JPG, PNG, ...) from the file extension,
*    unless the caller passes it explicitly.
  lv_dappl = iv_dappl.
  IF lv_dappl IS INITIAL.
    lv_name = iv_filename.
    FIND REGEX '\.([^.]+)$' IN lv_name SUBMATCHES lv_ext.
    TRANSLATE lv_ext TO UPPER CASE.
    IF lv_ext = 'JPEG'.
      lv_ext = 'JPG'.
    ENDIF.
    lv_dappl = lv_ext.
  ENDIF.

  lv_descr = iv_description.
  IF lv_descr IS INITIAL.
    lv_descr = iv_filename.
  ENDIF.

* 4) Create the document info record including the object link.
  ls_docdata-documenttype    = iv_dokar.
  ls_docdata-documentversion = '00'.
  ls_docdata-documentpart    = '000'.
  ls_docdata-description     = lv_descr.

  ls_objlink-objecttype = iv_dokob.
  ls_objlink-objectkey  = lv_objky.
  APPEND ls_objlink TO lt_objlinks.

  CALL FUNCTION 'BAPI_DOCUMENT_CREATE2'
    EXPORTING
      documentdata    = ls_docdata
    IMPORTING
      documentnumber  = ev_doknr
      documentpart    = ev_doktl
      documentversion = ev_dokvr
      return          = ls_return
    TABLES
      objectlinks     = lt_objlinks.
  IF ls_return-type CA 'EA'.
    APPEND ls_return TO et_return.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    CLEAR: ev_doknr, ev_dokvr, ev_doktl.
    RETURN.
  ENDIF.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

* 5) Split the binary content into DRAO blocks of 2550 bytes.
  lv_off = 0.
  lv_cnt = 0.
  WHILE lv_off < lv_size.
    lv_len = lv_size - lv_off.
    IF lv_len > 2550.
      lv_len = 2550.
    ENDIF.
    lv_cnt = lv_cnt + 1.
    CLEAR ls_drao.
    ls_drao-dokar = iv_dokar.
    ls_drao-doknr = ev_doknr.
    ls_drao-dokvr = ev_dokvr.
    ls_drao-doktl = ev_doktl.
    ls_drao-appnr = '1'.
    ls_drao-zaehl = lv_cnt.
    ls_drao-orln  = lv_size.
    ls_drao-orbkl = lv_len.
    ls_drao-orblk = lv_xstr+lv_off(lv_len).
    APPEND ls_drao TO lt_drao.
    lv_off = lv_off + lv_len.
  ENDWHILE.

* 6) Check the original in from the internal table
*    (PF_CONTENT_PROVIDE = 'TBL') into the storage category.
  ls_file-updateflag  = 'I'.
  ls_file-appnr       = '1'.
  ls_file-dappl       = lv_dappl.
  ls_file-storage_cat = iv_storage_cat.
  ls_file-filename    = iv_filename.
  ls_file-description = lv_descr.
  APPEND ls_file TO lt_files.

  ls_api-commit_flag = 'X'.

  CALL FUNCTION 'CVAPI_DOC_CHECKIN'
    EXPORTING
      pf_dokar           = iv_dokar
      pf_doknr           = ev_doknr
      pf_dokvr           = ev_dokvr
      pf_doktl           = ev_doktl
      ps_api_control     = ls_api
      pf_content_provide = 'TBL'
    IMPORTING
      psx_message        = ls_msg
    TABLES
      pt_files_x         = lt_files
      pt_content         = lt_drao.

  CLEAR ls_return.
  IF ls_msg-msg_type CA 'EA'.
*   The document info record exists, but the original could not be
*   checked in. EV_DOKNR stays filled so the caller can react.
    ls_return-type       = ls_msg-msg_type.
    ls_return-id         = ls_msg-msg_id.
    ls_return-number     = ls_msg-msg_no.
    ls_return-message    = ls_msg-msg_txt.
    ls_return-message_v1 = ls_msg-msg_v1.
    ls_return-message_v2 = ls_msg-msg_v2.
    ls_return-message_v3 = ls_msg-msg_v3.
    ls_return-message_v4 = ls_msg-msg_v4.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  ls_return-type = 'S'.
  CONCATENATE 'Document' iv_dokar ev_doknr ev_dokvr ev_doktl
              'created, original checked in'
         INTO ls_return-message SEPARATED BY space.
  APPEND ls_return TO et_return.

ENDFUNCTION.
