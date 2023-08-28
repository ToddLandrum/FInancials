* fixexprun
*
*  Fixes runno and run year for JIB expenses 
*
*  2/23/03 - pws
*

if not used('expense')
   use expense in 0
endif

sele expense
scan FOR EMPTY(crunyearjib) 
   wait wind nowait 'One-time expense processing.... ' + expense.cwellid
   IF NOT EMPTY(crunyearrev)
      repl crunyearjib with crunyearrev, ;
           nrunnojib with nrunnorev 
   ENDIF        
ENDSCAN          
      
                  