LOCAL m.lcPath
m.lcPath = m.goapp.cCommonfolder
lcFilename = m.lcPath+"XFRX_DIAG_" + STRTRAN(DTOC(DATE()),'/','') + ".TXT"
DO XFRX WITH "XFRX#DIAGNOSIS", lcFileName
MODIFY FILE (lcFileName) NOWAIT
