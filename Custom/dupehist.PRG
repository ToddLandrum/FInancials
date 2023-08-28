swselect('disbhist')

make_copy('disbhist', 'delrecs')
SELECT delrecs
INDEX ON crectype + crunyear_in + PADL(TRANSFORM(nrunno_in), 3, '0') + cownerid + cwellid TAG delkey
INDEX ON crectype TAG crectype
   
USE disbhist IN 0 AGAIN ALIAS ohist
SELECT disbhist 
COUNT FOR crunyear > '2019' TO lnmax 
lcMax = TRANSFORM(lnMax)
lncount = 1
 SELECT ohist
   SCAN FOR crunyear > '2019'
      SCATTER MEMVAR
      WAIT WINDOW NOWAIT 'Processing: ' + TRANSFORM(lncount) + ' of ' + lcMax
      lnCount  = lnCount + 1
      lciddisb = m.ciddisb

      * Scan through disbhist and only look at run year 2020 and beyond.
      * The suspense duplicate bug started near the end of 2020 so there
      * shouldn't be any runs before 2020 that have the problem.
      SELECT disbhist
      SCAN  FOR crunyear > "2019" ;
            AND cownerid = m.cownerid AND cwellid = m.cwellid AND nrunno_in = m.nrunno_in  ;
            AND crunyear_in = m.crunyear_in  AND nnetcheck = m.nnetcheck AND nnetcheck # 0  ;
            AND hyear = m.hyear AND hperiod = m.hperiod AND ctypeinv = m.ctypeinv AND ciddisb <> lciddisb ;
            AND ciddisb <> '#'
         m.crectype = 'H'
         SELECT delrecs
         LOCATE FOR ciddisb == disbhist.ciddisb
         IF NOT FOUND()
               m.ciddisb = disbhist.ciddisb
               INSERT INTO delrecs FROM MEMVAR
               m.ciddisb = lciddisb
         ENDIF
      ENDSCAN
   ENDSCAN
   WAIT CLEAR