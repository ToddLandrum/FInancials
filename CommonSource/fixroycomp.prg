if not used('wells')
   use wells in 0
endif
if not used('options')
   use options in 0
endif

sele options
go top
m.lRoyComp = lroycomp

sele wells
scan
   repl lexclroycomp with m.lroycomp
endscan         