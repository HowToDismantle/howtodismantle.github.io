FUNCTION z_pb_doc_get_base64.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_DOKOB) LIKE  DRAD-DOKOB DEFAULT 'MARA'
*"     VALUE(IV_OBJKY) LIKE  DRAD-OBJKY
*"     VALUE(IV_DOKAR) TYPE  DOKAR DEFAULT 'DRW'
*"  EXPORTING
*"     VALUE(EV_DOKNR) TYPE  DOKNR
*"     VALUE(EV_FILENAME) TYPE  SDOK_FILNM
*"     VALUE(EV_FILESIZE) TYPE  INT4
*"     VALUE(EV_DOKAR) TYPE  DOKAR
*"  TABLES
*"      ET_BASE64 STRUCTURE  SOLI
*"  EXCEPTIONS
*"      NOT_FOUND
*"      READ_ERROR
*"----------------------------------------------------------------------

  DATA: lv_dokar TYPE drad-dokar,
        lv_doknr TYPE drad-doknr,
        lv_dokvr TYPE drad-dokvr,
        lv_doktl TYPE drad-doktl,
        lv_loio  TYPE dms_doc2loio-lo_objid,
        lv_phio  TYPE dms_ph_cd1-phio_id,
        lv_stcat TYPE dms_ph_cd1-stor_cat,
        lv_objky TYPE drad-objky,
        lv_matnr TYPE matnr,
        lt_phio  TYPE STANDARD TABLE OF dms_ph_cd1,
        ls_phio  TYPE dms_ph_cd1,
        lt_acinf TYPE STANDARD TABLE OF scms_acinf,
        ls_acinf TYPE scms_acinf,
        lt_bin   TYPE STANDARD TABLE OF sdokcntbin,
        lv_xstr  TYPE xstring,
        lv_b64   TYPE string,
        lv_len   TYPE i,
        lv_off   TYPE i,
        lv_sub   TYPE i,
        ls_line  TYPE soli.

  CLEAR: ev_doknr, ev_filename, ev_filesize, ev_dokar.
  REFRESH et_base64.

* The material number is the only object key that carries a conversion
* exit, so purely numeric material numbers have to be padded first.
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

* Step 1 - find the document info record linked to the object.
* An empty IV_DOKAR searches across all document types.
  IF iv_dokar IS INITIAL.
    SELECT SINGLE dokar doknr dokvr doktl
      INTO (lv_dokar, lv_doknr, lv_dokvr, lv_doktl)
      FROM drad
      WHERE dokob = iv_dokob
        AND objky = lv_objky.
  ELSE.
    SELECT SINGLE dokar doknr dokvr doktl
      INTO (lv_dokar, lv_doknr, lv_dokvr, lv_doktl)
      FROM drad
      WHERE dokob = iv_dokob
        AND objky = lv_objky
        AND dokar = iv_dokar.
  ENDIF.
  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.

* Step 2 - resolve the logical object id (LOIO) of the original.
  SELECT SINGLE lo_objid INTO lv_loio
    FROM dms_doc2loio
    WHERE dokar = lv_dokar
      AND doknr = lv_doknr
      AND dokvr = lv_dokvr
      AND doktl = lv_doktl.
  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.

* Step 3 - resolve the physical object id (PHIO) and the storage
* category. If several versions exist, take the most recent one.
  SELECT * FROM dms_ph_cd1 INTO TABLE lt_phio
    WHERE loio_id = lv_loio.
  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.
  SORT lt_phio BY chng_time DESCENDING.
  READ TABLE lt_phio INTO ls_phio INDEX 1.
  lv_phio  = ls_phio-phio_id.
  lv_stcat = ls_phio-stor_cat.

* Step 4 - read the binary content out of the content server.
  CALL FUNCTION 'SCMS_DOC_READ'
    EXPORTING
      stor_cat    = lv_stcat
      doc_id      = lv_phio
      phio_id     = lv_phio
    TABLES
      access_info = lt_acinf
      content_bin = lt_bin
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    RAISE read_error.
  ENDIF.

* ACCESS_INFO carries the file name and the real byte size. The size
* matters: the last RAW line is padded with null bytes.
  READ TABLE lt_acinf INTO ls_acinf INDEX 1.
  IF sy-subrc = 0.
    ev_filename = ls_acinf-comp_id.
    lv_len      = ls_acinf-comp_size.
  ENDIF.

  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_len
    IMPORTING
      buffer       = lv_xstr
    TABLES
      binary_tab   = lt_bin
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
    RAISE read_error.
  ENDIF.

  lv_b64 = cl_http_utility=>encode_x_base64( lv_xstr ).

  ev_dokar    = lv_dokar.
  ev_doknr    = lv_doknr.
  ev_filesize = lv_len.

* Chop the Base64 string into 255 character chunks so it fits into SOLI.
  lv_len = strlen( lv_b64 ).
  lv_off = 0.
  WHILE lv_off < lv_len.
    lv_sub = lv_len - lv_off.
    IF lv_sub > 255.
      lv_sub = 255.
    ENDIF.
    ls_line-line = lv_b64+lv_off(lv_sub).
    APPEND ls_line TO et_base64.
    lv_off = lv_off + lv_sub.
  ENDWHILE.

ENDFUNCTION.
