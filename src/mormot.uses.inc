{
  This file is a part of the freeware Synopse mORMot framework 2,
  licensed under a MPL/GPL/LGPL three license - see LICENSE.md

  Content of this file should be part of the .dpr/.lpr main uses clauses,
  to ensure proper cross-platform process.
}


{$ifdef FPC} // we may be on Kylix or upcoming Delphi for Linux
  {$ifdef FPC_X64MM}
    mormot.core.fpcx64mm, // redirect to our optimized x86_64 asm Memory Manager
  {$endif FPC_X64MM}
  {$ifdef Unix} // we may also be on Darwin / OSX
    cthreads, // if you use threads: always needed for servers
    {$ifdef Darwin}
      iosxwstr, // optional WideString manager for Mac, but won't hurt
    {$else}
      cwstring, // optional WideString manager, but won't hurt
    {$endif Darwin}
  {$else}
    {$ifopt D-} // at the moment, debug mode with cmem causes trouble
      //cmem, // default FPC's heap manager is very RAM hungry (one heap per thread)
    {$endif}
  //FastMM4,  // need the latest version, e.g. from lib\kylix sub folder
  {$endif Unix}
{$else}  // enable FastMM4 on older versions of Delphi
  {$IFDEF CONDITIONALEXPRESSIONS}
    {$if CompilerVersion <= 17} // Delphi 2006 (and up) have FastMM4 integrated
      FastMM4,
    {$ifend}
    {$ifdef UNICODE}
      {$warn DUPLICATE_CTOR_DTOR OFF} // global at .dpr level - see QC 100815
    {$endif}
  {$ELSE}
    FastMM4, // no conditional expressions -> versions older than Delphi 6
  {$ENDIF}
{$endif FPC}

