function zrfc_call_report.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(DELIMITER) TYPE  CHAR1
*"     VALUE(REPORT) TYPE  CHAR25
*"  EXPORTING
*"     VALUE(ERRORCODE) TYPE  I
*"     VALUE(ERRORMSG) TYPE  STRING
*"  TABLES
*"      FIELDLIST STRUCTURE  TAB512
*"      DATA STRUCTURE  TAB512
*"      SELECTION STRUCTURE  RSPARAMS OPTIONAL
*"----------------------------------------------------------------------

* Author: Andre Sieverding
* Date: 05.12.2019

*  Data declaration
*  Define fildlist structure type -> Table of this structure are going to be converted to csv data and moved to FIELDLIST table
  types: begin of lty_fieldlist,
           fieldname(25) type c,
           seltext(25)   type c,
           tooltip(25)   type c,
           reptext(25)   type c,
           domname(25)   type c,
         end of lty_fieldlist.

*  Define variables
  data: lr_pay_data     type ref to data,
        ls_data         like line of data,
        lt_fieldlist    type table of lty_fieldlist,
        ls_fieldlist    like line of lt_fieldlist,
        lt_table_csv    type truxs_t_text_data,
        ls_table_csv    type line of truxs_t_text_data,
        lo_table_descr  type ref to cl_abap_tabledescr,
        lo_struct_descr type ref to cl_abap_structdescr,
        lt_columns      type abap_compdescr_tab.

*  Define field symbols
  field-symbols: <lt_pay_data> type standard table,
                 <lf_column>   like line of lt_columns.

*  Clear tables
  refresh: fieldlist, data.
  free: fieldlist, data.

*  Prompt SAP to use alv data from ABAP runtime
*  We need metadata & data
  cl_salv_bs_runtime_info=>set(
    exporting display  = abap_false
              metadata = abap_true
              data     = abap_true ).

*  Call report (with selection-screen parameters)
  describe table selection lines data(lv_lines).
  if lv_lines > 0.
    submit (report) with selection-table selection and return.
  else.
    submit (report) and return.
  endif.

*  Try to get report alv metadata & data from ABAP runtime
  try.
      data(lv_metadata) = cl_salv_bs_runtime_info=>get_metadata( ).
      cl_salv_bs_runtime_info=>get_data_ref(
        importing r_data = lr_pay_data ).
      assign lr_pay_data->* to <lt_pay_data>.
    catch cx_salv_bs_sc_runtime_info.
*      Error
      refresh: fieldlist, data.
      free: fieldlist, data.
      errorcode = 1.
      errormsg = 'Cannot get ALV data from ABAP runtime!'.
      return.
  endtry.

  cl_salv_bs_runtime_info=>clear_all( ).

*  Define metadata structure
  data: ls_metadata    like line of lv_metadata-t_fcat.

* Get component list from data table
  lo_table_descr ?= cl_abap_typedescr=>describe_by_data( <lt_pay_data> ).
  lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
  lt_columns = lo_struct_descr->components.

*  Add columns / components to the fieldlist
  loop at lt_columns assigning <lf_column>.
    clear: ls_fieldlist.

*    Get human readable column names for current column from alv metadata
    read table lv_metadata-t_fcat into ls_metadata with key fieldname = <lf_column>-name.

*    Build fieldlist table entry
    ls_fieldlist-fieldname = ls_metadata-fieldname.
    ls_fieldlist-seltext = ls_metadata-seltext.
    ls_fieldlist-tooltip = ls_metadata-tooltip.
    ls_fieldlist-reptext = ls_metadata-reptext.
    ls_fieldlist-domname = ls_metadata-domname.
    insert ls_fieldlist into table lt_fieldlist.
  endloop.

*  Convert fieldlist table to csv
  clear: lt_table_csv, ls_table_csv.
  call function 'SAP_CONVERT_TO_TEX_FORMAT'
    exporting
      i_field_seperator    = delimiter
      i_line_header        = ''
    tables
      i_tab_sap_data       = lt_fieldlist
    changing
      i_tab_converted_data = lt_table_csv
    exceptions
      conversion_failed    = 1
      others               = 2.
  if sy-subrc <> 0.
*    Error
    refresh: fieldlist, data.
    free: fieldlist, data.
    errorcode = 2.
    errormsg = 'Fieldlist payload to csv conversion has failed!'.
    return.
  endif.

*  Loop through csv records and add them to the FIELDLIST table
  loop at lt_table_csv assigning field-symbol(<f>).
    ls_data-wa = <f>.
    insert ls_data into table fieldlist.
  endloop.

*  Convert alv data to csv
  clear: lt_table_csv, ls_table_csv.
  call function 'SAP_CONVERT_TO_TEX_FORMAT'
    exporting
      i_field_seperator    = delimiter
      i_line_header        = ''
    tables
      i_tab_sap_data       = <lt_pay_data>
    changing
      i_tab_converted_data = lt_table_csv
    exceptions
      conversion_failed    = 1
      others               = 2.
  if sy-subrc <> 0.
*    Error
    refresh: fieldlist, data.
    free: fieldlist, data.
    errorcode = 2.
    errormsg = 'Data payload to csv conversion has failed!'.
    return.
  endif.

*  Loop through csv records and add them to the DATA table
  loop at lt_table_csv assigning field-symbol(<row>).
    ls_data-wa = <row>.
    insert ls_data into table data.
  endloop.

*  Set error code exporting parameter to 0 & clear error message
  errorcode = 0.
  clear: errormsg.
endfunction.
