#include "hbclass.ch"
#include "hwgui.ch"
#include "dbstruct.ch"
#include "dlgauto.ch"

CREATE CLASS DlgAutoMainClass INHERIT DlgAutoEditClass

   VAR cTitle
   VAR cFileDBF
   VAR aEditList INIT {}
   METHOD Execute()
   METHOD View()    INLINE Nil
   METHOD Edit()
   METHOD Delete()      INLINE Nil
   METHOD Insert()      INLINE Nil
   METHOD First()       INLINE &( ::cFileDbf )->( dbgotop() ),    ::EditUpdate()
   METHOD Last()        INLINE &( ::cFileDbf )->( dbgobottom() ), ::EditUpdate()
   METHOD Next()        INLINE &( ::cFileDbf )->( dbSkip() ),     ::EditUpdate()
   METHOD Previous()    INLINE &( ::cFileDbf )->( dbSkip( -1 ) ), ::EditUpdate()
   METHOD Exit()        INLINE ::oDlg:Close()
   METHOD Save()
   METHOD Cancel()
   VAR oDlg

   ENDCLASS

METHOD Edit() CLASS DlgAutoMainClass

   ::EditOn()

   RETURN Nil

METHOD Save() CLASS DlgAutoMainClass

   LOCAL aItem

   ::EditOff()
   RLock()
   FOR EACH aItem IN ::aControlList
      IF aItem[ CFG_CTLTYPE ] == TYPE_EDIT
         IF ! Empty( aItem[ CFG_NAME ] )
            FieldPut( FieldNum( aItem[ CFG_NAME ] ), aItem[ CFG_VALUE ] )
         ENDIF
      ENDIF
   NEXT
   SKIP 0
   UNLOCK

   RETURN Nil

METHOD Cancel() CLASS DlgAutoMainClass

   ::EditOff()
   ::EditUpdate()

   RETURN Nil

METHOD Execute() CLASS DlgAutoMainClass

   SELECT 0
   USE ( ::cFileDBF )
   ::EditSetup()

   INIT DIALOG ::oDlg CLIPPER NOEXIT TITLE ::cTitle ;
      AT 0, 0 SIZE ::nDlgWidth, ::nDlgHeight ;
      BACKCOLOR STYLE_BACK ;
      ON EXIT hwg_EndDialog() ;
      ON INIT { || ::EditUpdate() }
   ::ButtonCreate()
   ::EditCreate()
   ACTIVATE DIALOG ::oDlg CENTER

   RETURN Nil
