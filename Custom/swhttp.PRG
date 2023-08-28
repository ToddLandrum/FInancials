DEFINE CLASS wwHttp_WithEvents AS wwHTTP

    FUNCTION OnHttpBufferUpdate
    LPARAMETERS lnbytes, lnbufferreads, lccurrentchunk, loHttp

    DO CASE
*** 0 - Http Header
        CASE lnbufferreads = 0
            lcHttpHeader = lccurrentchunk
*** -1 - done or cancelled or failed
        CASE lnbufferreads = -1
* done or cancelled         
            IF THIS.lhttpcanceldownload
                WAIT wind "Canceled"
            ELSE
                WAIT wind NOWAIT "Completed..."
            ENDIF
*** anything else - data has been read
        CASE lnbufferreads > 0
            WAIT WINDOW 'Downloading ' + TRANSFORM(lnbytes, "999,999,999") + " of " + TRANSFORM(THIS.nContentSize, "999,999,999") + " bytes" NOWAIT
    ENDCASE

ENDDEFINE