swselect('wellinv')
swselect('disbhist')
swselect('suspense')
swselect('ownpcts')

WAIT WINDOW NOWAIT 'Scanning Ownpcts...'
SELECT ownpcts
SCAN
   IF nrevgas=0 AND nrevoil=0 AND nworkint = 0
      SCATTER MEMVAR
      SELECT disbhist
      LOCATE FOR ciddisb==m.ciddisb
      IF FOUND()
         m.ctypeinv = ctypeinv
         m.cownerid = cownerid
         m.cwellid  = cwellid
         WAIT WINDOW NOWAIT 'Processing Ownpcts owner: ' + m.cownerid+'/'+m.cwellid
         SELECT wellinv
         LOCATE FOR cownerid==m.cownerid AND cwellid==m.cwellid AND ctypeinv==m.ctypeinv
         SCATTER MEMVAR
         SELECT ownpcts
         GATHER MEMVAR
      ENDIF
   ENDIF
ENDSCAN
WAIT WINDOW NOWAIT 'Scanning Suspense...'
SELECT suspense
SCAN
   IF nrevgas=0 AND nrevoil=0 AND nworkint = 0
      SCATTER MEMVAR
      WAIT WINDOW NOWAIT 'Processing Suspense owner: ' + m.cownerid+'/'+m.cwellid

      SELECT wellinv
      LOCATE FOR cownerid==m.cownerid AND cwellid==m.cwellid AND ctypeinv==m.ctypeinv
      SCATTER MEMVAR
      SELECT suspense
      GATHER MEMVAR
   ENDIF
ENDSCAN

WAIT WINDOW 'Ownpcts utility is finished....' NOWAIT
