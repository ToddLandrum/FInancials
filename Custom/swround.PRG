LPARA tnAmount, tnDec
local lnx, lnAmount

lnAmount = tnAmount

for lnx = 30 to tnDec step -1
   lnAmount = round(lnAmount,lnx)
endfor

RETURN (lnAmount)
