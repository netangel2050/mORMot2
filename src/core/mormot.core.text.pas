/// Framework Core Low-Level Text Processing
// - this unit is a part of the freeware Synopse mORMot framework 2,
// licensed under a MPL/GPL/LGPL three license - see LICENSE.md
unit mormot.core.text;

{
  *****************************************************************************

   Text Processing functions shared by all framework units
    - UTF-8 String Manipulation Functions
    - TRawUTF8DynArray Processing Functions
    - CSV-like Iterations over Text Buffers
    - TBaseWriter parent class for Text Generation
    - Numbers (integers or floats) and Variants to Text Conversion
    - Hexadecimal Text And Binary Conversion
    - Text Formatting functions and ESynException class
    - Resource and Time Functions

  *****************************************************************************
}

interface

{$I ..\mormot.defines.inc}

uses
  classes,
  contnrs,
  types,
  sysutils,
  mormot.core.base,
  mormot.core.os,
  mormot.core.unicode;


{ ************ UTF-8 String Manipulation Functions }

type
  /// used to store a set of 8-bit encoded characters
  TSynAnsicharSet = set of AnsiChar;
  /// used to store a set of 8-bit unsigned integers
  TSynByteSet = set of Byte;

/// extract a line from source array of chars
// - next will contain the beginning of next line, or nil if source if ended
function GetNextLine(source: PUTF8Char; out next: PUTF8Char;
  andtrim: boolean = false): RawUTF8;

/// trims leading whitespace characters from the string by removing
// new line, space, and tab characters
function TrimLeft(const S: RawUTF8): RawUTF8;

/// trims trailing whitespace characters from the string by removing trailing
// newline, space, and tab characters
function TrimRight(const S: RawUTF8): RawUTF8;

// single-allocation (therefore faster) alternative to Trim(copy())
procedure TrimCopy(const S: RawUTF8; start, count: PtrInt; out result: RawUTF8);

/// split a RawUTF8 string into two strings, according to SepStr separator
// - if SepStr is not found, LeftStr=Str and RightStr=''
// - if ToUpperCase is TRUE, then LeftStr and RightStr will be made uppercase
procedure Split(const Str, SepStr: RawUTF8; var LeftStr, RightStr: RawUTF8;
  ToUpperCase: boolean = false); overload;

/// split a RawUTF8 string into two strings, according to SepStr separator
// - this overloaded function returns the right string as function result
// - if SepStr is not found, LeftStr=Str and result=''
// - if ToUpperCase is TRUE, then LeftStr and result will be made uppercase
function Split(const Str, SepStr: RawUTF8; var LeftStr: RawUTF8;
  ToUpperCase: boolean = false): RawUTF8; overload;

/// split a RawUTF8 string into several strings, according to SepStr separator
// - this overloaded function will fill a DestPtr[] array of PRawUTF8
// - if any DestPtr[]=nil, the item will be skipped
// - if input Str end before al SepStr[] are found, DestPtr[] is set to ''
// - returns the number of values extracted into DestPtr[]
function Split(const Str: RawUTF8; const SepStr: array of RawUTF8;
  const DestPtr: array of PRawUTF8): PtrInt; overload;

/// returns the last occurence of the given SepChar separated context
// - e.g. SplitRight('01/2/34','/')='34'
// - if SepChar doesn't appear, will return Str, e.g. SplitRight('123','/')='123'
// - if LeftStr is supplied, the RawUTF8 it points to will be filled with
// the left part just before SepChar ('' if SepChar doesn't appear)
function SplitRight(const Str: RawUTF8; SepChar: AnsiChar; LeftStr: PRawUTF8 = nil): RawUTF8;

/// returns the last occurence of the given SepChar separated context
// - e.g. SplitRight('path/one\two/file.ext','/\')='file.ext', i.e.
// SepChars='/\' will be like ExtractFileName() over RawUTF8 string
// - if SepChar doesn't appear, will return Str, e.g. SplitRight('123','/')='123'
function SplitRights(const Str, SepChar: RawUTF8): RawUTF8;

/// fill all bytes of this memory buffer with zeros, i.e. 'toto' -> #0#0#0#0
// - will write the memory buffer directly, so if this string instance is shared
// (i.e. has refcount>1), all other variables will contains zeros
// - may be used to cleanup stack-allocated content
// ! ... finally FillZero(secret); end;
procedure FillZero(var secret: RawByteString); overload;

/// fill all bytes of this UTF-8 string with zeros, i.e. 'toto' -> #0#0#0#0
// - will write the memory buffer directly, so if this string instance is shared
// (i.e. has refcount>1), all other variables will contains zeros
// - may be used to cleanup stack-allocated content
// ! ... finally FillZero(secret); end;
procedure FillZero(var secret: RawUTF8); overload;

/// fill all bytes of this UTF-8 string with zeros, i.e. 'toto' -> #0#0#0#0
// - SPIUTF8 type has been defined explicitely to store Sensitive Personal
// Information
procedure FillZero(var secret: SPIUTF8); overload;

/// actual replacement function called by StringReplaceAll() on first match
// - not to be called as such, but defined globally for proper inlining
function StringReplaceAllProcess(const S, OldPattern, NewPattern: RawUTF8;
  found: integer): RawUTF8;

/// fast version of StringReplace(S, OldPattern, NewPattern,[rfReplaceAll]);
function StringReplaceAll(const S, OldPattern, NewPattern: RawUTF8): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// fast version of several cascaded StringReplaceAll()
function StringReplaceAll(const S: RawUTF8; const OldNewPatternPairs: array of RawUTF8): RawUTF8; overload;

/// fast replace of a specified char by a given string
function StringReplaceChars(const Source: RawUTF8; OldChar, NewChar: AnsiChar): RawUTF8;

/// fast replace of all #9 chars by a given string
function StringReplaceTabs(const Source, TabText: RawUTF8): RawUTF8;

/// format a text content with SQL-like quotes
// - UTF-8 version of the function available in SysUtils
// - this function implements what is specified in the official SQLite3
// documentation: "A string constant is formed by enclosing the string in single
// quotes ('). A single quote within the string can be encoded by putting two
// single quotes in a row - as in Pascal."
function QuotedStr(const S: RawUTF8; Quote: AnsiChar = ''''): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// format a text content with SQL-like quotes
// - UTF-8 version of the function available in SysUtils
// - this function implements what is specified in the official SQLite3
// documentation: "A string constant is formed by enclosing the string in single
// quotes ('). A single quote within the string can be encoded by putting two
// single quotes in a row - as in Pascal."
procedure QuotedStr(const S: RawUTF8; Quote: AnsiChar; var result: RawUTF8); overload;

/// unquote a SQL-compatible string
// - the first character in P^ must be either ' or " then internal double quotes
// are transformed into single quotes
// - 'text '' end'   -> text ' end
// - "text "" end"   -> text " end
// - returns nil if P doesn't contain a valid SQL string
// - returns a pointer just after the quoted text otherwise
function UnQuoteSQLStringVar(P: PUTF8Char; out Value: RawUTF8): PUTF8Char;

/// unquote a SQL-compatible string
function UnQuoteSQLString(const Value: RawUTF8): RawUTF8;

/// unquote a SQL-compatible symbol name
// - e.g. '[symbol]' -> 'symbol' or '"symbol"' -> 'symbol'
function UnQuotedSQLSymbolName(const ExternalDBSymbol: RawUTF8): RawUTF8;


/// get the next character after a quoted buffer
// - the first character in P^ must be either ', either "
// - it will return the latest quote position, ignoring double quotes within
function GotoEndOfQuotedString(P: PUTF8Char): PUTF8Char;
  {$ifdef HASINLINE} inline; {$endif}

/// get the next character not in [#1..' ']
function GotoNextNotSpace(P: PUTF8Char): PUTF8Char;
  {$ifdef HASINLINE} inline; {$endif}

/// get the next character not in [#9,' ']
function GotoNextNotSpaceSameLine(P: PUTF8Char): PUTF8Char;
  {$ifdef HASINLINE} inline; {$endif}

/// get the next character in [#1..' ']
function GotoNextSpace(P: PUTF8Char): PUTF8Char;
  {$ifdef HASINLINE} inline; {$endif}

/// check if the next character not in [#1..' '] matchs a given value
// - first ignore any non space character
// - then returns TRUE if P^=ch, setting P to the character after ch
// - or returns FALSE if P^<>ch, leaving P at the level of the unexpected char
function NextNotSpaceCharIs(var P: PUTF8Char; ch: AnsiChar): boolean;
  {$ifdef HASINLINE} inline; {$endif}

/// retrieve the next SQL-like identifier within the UTF-8 buffer
// - will also trim any space (or line feeds) and trailing ';'
// - returns true if something was set to Prop
function GetNextFieldProp(var P: PUTF8Char; var Prop: RawUTF8): boolean;

/// retrieve the next identifier within the UTF-8 buffer on the same line
// - GetNextFieldProp() will just handle line feeds (and ';') as spaces - which
// is fine e.g. for SQL, but not for regular config files with name/value pairs
// - returns true if something was set to Prop
function GetNextFieldPropSameLine(var P: PUTF8Char; var Prop: ShortString): boolean;

/// return true if IdemPChar(source,searchUp), and go to the next line of source
function IdemPCharAndGetNextLine(var source: PUTF8Char; searchUp: PAnsiChar): boolean;

/// search for a value from its uppercased named entry
// - i.e. iterate IdemPChar(source,UpperName) over every line of the source
// - returns the text just after UpperName if it has been found at line beginning
// - returns nil if UpperName was not found at any line beginning
// - could be used as alternative to FindIniNameValue() and FindIniNameValueInteger()
// if there is no section, i.e. if search should not stop at '[' but at source end
function FindNameValue(P: PUTF8Char; UpperName: PAnsiChar): PUTF8Char; overload;

/// search and returns a value from its uppercased named entry
// - i.e. iterate IdemPChar(source,UpperName) over every line of the source
// - returns true and the trimmed text just after UpperName into Value
// if it has been found at line beginning
// - returns false and set Value := '' if UpperName was not found
// - could be used e.g. to efficently extract a value from HTTP headers, whereas
// FindIniNameValue() is tuned for [section]-oriented INI files
function FindNameValue(const NameValuePairs: RawUTF8; UpperName: PAnsiChar;
  var Value: RawUTF8): boolean; overload;

/// compute the line length from source array of chars
// - if PEnd = nil, end counting at either #0, #13 or #10
// - otherwise, end counting at either #13 or #10
// - just a wrapper around BufferLineLength() checking PEnd=nil case
function GetLineSize(P, PEnd: PUTF8Char): PtrUInt;
  {$ifdef HASINLINE} inline; {$endif}

/// returns true if the line length from source array of chars is not less than
// the specified count
function GetLineSizeSmallerThan(P, PEnd: PUTF8Char; aMinimalCount: integer): boolean;

/// return next string delimited with #13#10 from P, nil if no more
// - this function returns a RawUnicode string type
function GetNextStringLineToRawUnicode(var P: PChar): RawUnicode;

/// trim first lowercase chars ('otDone' will return 'Done' e.g.)
// - return a PUTF8Char to avoid any memory allocation
function TrimLeftLowerCase(const V: RawUTF8): PUTF8Char;

/// trim first lowercase chars ('otDone' will return 'Done' e.g.)
// - return an RawUTF8 string: enumeration names are pure 7bit ANSI with Delphi 7
// to 2007, and UTF-8 encoded with Delphi 2009+
function TrimLeftLowerCaseShort(V: PShortString): RawUTF8;

/// trim first lowercase chars ('otDone' will return 'Done' e.g.)
// - return a shortstring: enumeration names are pure 7bit ANSI with Delphi 7
// to 2007, and UTF-8 encoded with Delphi 2009+
function TrimLeftLowerCaseToShort(V: PShortString): ShortString; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// trim first lowercase chars ('otDone' will return 'Done' e.g.)
// - return a shortstring: enumeration names are pure 7bit ANSI with Delphi 7
// to 2007, and UTF-8 encoded with Delphi 2009+
procedure TrimLeftLowerCaseToShort(V: PShortString; out result: ShortString); overload;

/// fast append some UTF-8 text into a shortstring, with an ending ','
procedure AppendShortComma(text: PAnsiChar; len: PtrInt; var result: shortstring;
  trimlowercase: boolean);   {$ifdef FPC} inline; {$endif}

/// fast search of an exact case-insensitive match of a RTTI's PShortString array
function FindShortStringListExact(List: PShortString; MaxValue: integer;
  aValue: PUTF8Char; aValueLen: PtrInt): integer;

/// fast case-insensitive search of a left-trimmed lowercase match
// of a RTTI's PShortString array
function FindShortStringListTrimLowerCase(List: PShortString; MaxValue: integer;
  aValue: PUTF8Char; aValueLen: PtrInt): integer;

/// fast case-sensitive search of a left-trimmed lowercase match
// of a RTTI's PShortString array
function FindShortStringListTrimLowerCaseExact(List: PShortString; MaxValue: integer;
  aValue: PUTF8Char; aValueLen: PtrInt): integer;

/// convert a CamelCase string into a space separated one
// - 'OnLine' will return 'On line' e.g., and 'OnMyLINE' will return 'On my LINE'
// - will handle capital words at the beginning, middle or end of the text, e.g.
// 'KLMFlightNumber' will return 'KLM flight number' and 'GoodBBCProgram' will
// return 'Good BBC program'
// - will handle a number at the beginning, middle or end of the text, e.g.
// 'Email12' will return 'Email 12'
// - '_' char is transformed into ' - '
// - '__' chars are transformed into ': '
// - return an RawUTF8 string: enumeration names are pure 7bit ANSI with Delphi 7
// to 2007, and UTF-8 encoded with Delphi 2009+
function UnCamelCase(const S: RawUTF8): RawUTF8; overload;

/// convert a CamelCase string into a space separated one
// - 'OnLine' will return 'On line' e.g., and 'OnMyLINE' will return 'On my LINE'
// - will handle capital words at the beginning, middle or end of the text, e.g.
// 'KLMFlightNumber' will return 'KLM flight number' and 'GoodBBCProgram' will
// return 'Good BBC program'
// - will handle a number at the beginning, middle or end of the text, e.g.
// 'Email12' will return 'Email 12'
// - return the char count written into D^
// - D^ and P^ are expected to be UTF-8 encoded: enumeration and property names
// are pure 7bit ANSI with Delphi 7 to 2007, and UTF-8 encoded with Delphi 2009+
// - '_' char is transformed into ' - '
// - '__' chars are transformed into ': '
function UnCamelCase(D, P: PUTF8Char): integer; overload;

/// convert a string into an human-friendly CamelCase identifier
// - replacing spaces or punctuations by an uppercase character
// - as such, it is not the reverse function to UnCamelCase()
procedure CamelCase(P: PAnsiChar; len: PtrInt; var s: RawUTF8;
  const isWord: TSynByteSet = [ord('0')..ord('9'),ord('a')..ord('z'),ord('A')..ord('Z')]); overload;

/// convert a string into an human-friendly CamelCase identifier
// - replacing spaces or punctuations by an uppercase character
// - as such, it is not the reverse function to UnCamelCase()
procedure CamelCase(const text: RawUTF8; var s: RawUTF8;
  const isWord: TSynByteSet = [ord('0')..ord('9'),ord('a')..ord('z'),ord('A')..ord('Z')]); overload;
  {$ifdef HASINLINE} inline; {$endif}

var
  /// these procedure type must be defined if a default system.pas is used
  // - expect generic "string" type, i.e. UnicodeString for Delphi 2009+
  LoadResStringTranslate: procedure(var Text: string) = nil;

/// UnCamelCase and translate a char buffer
// - P is expected to be #0 ended
// - return "string" type, i.e. UnicodeString for Delphi 2009+
procedure GetCaptionFromPCharLen(P: PUTF8Char; out result: string);


{ ************ CSV-like Iterations over Text Buffers }

/// return true if IdemPChar(source,searchUp) matches, and retrieve the value item
// - typical use may be:
// ! if IdemPCharAndGetNextItem(P,
// !   'CONTENT-DISPOSITION: FORM-DATA; NAME="',Name,'"') then ...
function IdemPCharAndGetNextItem(var source: PUTF8Char; const searchUp: RawUTF8;
  var Item: RawUTF8; Sep: AnsiChar = #13): boolean;

/// return next CSV string from P
// - P=nil after call when end of text is reached
function GetNextItem(var P: PUTF8Char; Sep: AnsiChar = ','): RawUTF8; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// return next CSV string from P
// - P=nil after call when end of text is reached
procedure GetNextItem(var P: PUTF8Char; Sep: AnsiChar; var result: RawUTF8); overload;

/// return next CSV string (unquoted if needed) from P
// - P=nil after call when end of text is reached
procedure GetNextItem(var P: PUTF8Char; Sep, Quote: AnsiChar; var result: RawUTF8); overload;

/// return trimmed next CSV string from P
// - P=nil after call when end of text is reached
procedure GetNextItemTrimed(var P: PUTF8Char; Sep: AnsiChar; var result: RawUTF8);

/// return next CRLF separated value string from P, ending #10 or #13#10 trimmed
// - any kind of line feed (CRLF or LF) will be handled, on all operating systems
// - as used e.g. by TSynNameValue.InitFromCSV and TDocVariantData.InitCSV
// - P=nil after call when end of text is reached
procedure GetNextItemTrimedCRLF(var P: PUTF8Char; var result: RawUTF8);

/// return next CSV string from P, nil if no more
// - this function returns the generic string type of the compiler, and
// therefore can be used with ready to be displayed text (e.g. for the VCL)
function GetNextItemString(var P: PChar; Sep: Char = ','): string;

/// extract a file extension from a file name, then compare with a comma
// separated list of extensions
// - e.g. GetFileNameExtIndex('test.log','exe,log,map')=1
// - will return -1 if no file extension match
// - will return any matching extension, starting count at 0
// - extension match is case-insensitive
function GetFileNameExtIndex(const FileName, CSVExt: TFileName): integer;

/// return next CSV string from P, nil if no more
// - output text would be trimmed from any left or right space
procedure GetNextItemShortString(var P: PUTF8Char; out Dest: ShortString; Sep: AnsiChar = ',');

/// append some text lines with the supplied Values[]
// - if any Values[] item is '', no line is added
// - otherwise, appends 'Caption: Value', with Caption taken from CSV
procedure AppendCSVValues(const CSV: string; const Values: array of string;
  var Result: string; const AppendBefore: string = #13#10);

/// return a CSV list of the iterated same value
// - e.g. CSVOfValue('?',3)='?,?,?'
function CSVOfValue(const Value: RawUTF8; Count: cardinal; const Sep: RawUTF8 = ','): RawUTF8;

 /// retrieve the next CSV separated bit index
// - each bit was stored as BitIndex+1, i.e. 0 to mark end of CSV chunk
// - several bits set to one can be regrouped via 'first-last,' syntax
procedure SetBitCSV(var Bits; BitsCount: integer; var P: PUTF8Char);

/// convert a set of bit into a CSV content
// - each bit is stored as BitIndex+1, and separated by a ','
// - several bits set to one can be regrouped via 'first-last,' syntax
// - ',0' is always appended at the end of the CSV chunk to mark its end
function GetBitCSV(const Bits; BitsCount: integer): RawUTF8;

/// decode next CSV hexadecimal string from P, nil if no more or not matching BinBytes
// - Bin is filled with 0 if the supplied CSV content is invalid
// - if Sep is #0, it will read the hexadecimal chars until a whitespace is reached
function GetNextItemHexDisplayToBin(var P: PUTF8Char; Bin: PByte; BinBytes: integer;
  Sep: AnsiChar = ','): boolean;

type
  /// some stack-allocated zero-terminated character buffer
  // - as used by GetNextTChar64
  TChar64 = array[0..63] of AnsiChar;

/// return next CSV string from P as a #0-ended buffer, false if no more
// - if Sep is #0, will copy all characters until next whitespace char
// - returns the number of bytes stored into Buf[]
function GetNextTChar64(var P: PUTF8Char; Sep: AnsiChar; out Buf: TChar64): PtrInt;

/// return next CSV string as unsigned integer from P, 0 if no more
// - if Sep is #0, it won't be searched for
function GetNextItemCardinal(var P: PUTF8Char; Sep: AnsiChar = ','): PtrUInt;

/// return next CSV string as signed integer from P, 0 if no more
// - if Sep is #0, it won't be searched for
function GetNextItemInteger(var P: PUTF8Char; Sep: AnsiChar = ','): PtrInt;

/// return next CSV string as 64-bit signed integer from P, 0 if no more
// - if Sep is #0, it won't be searched for
function GetNextItemInt64(var P: PUTF8Char; Sep: AnsiChar = ','): Int64;

/// return next CSV string as 64-bit unsigned integer from P, 0 if no more
// - if Sep is #0, it won't be searched for
function GetNextItemQWord(var P: PUTF8Char; Sep: AnsiChar = ','): QWord;

/// return next CSV hexadecimal string as 64-bit unsigned integer from P
// - returns 0 if no valid hexadecimal text is available in P
// - if Sep is #0, it won't be searched for
// - will first fill the 64-bit value with 0, then decode each two hexadecimal
// characters available in P
// - could be used to decode TBaseWriter.AddBinToHexDisplayMinChars() output
function GetNextItemHexa(var P: PUTF8Char; Sep: AnsiChar = ','): QWord;

/// return next CSV string as unsigned integer from P, 0 if no more
// - P^ will point to the first non digit character (the item separator, e.g.
// ',' for CSV)
function GetNextItemCardinalStrict(var P: PUTF8Char): PtrUInt;

/// return next CSV string as unsigned integer from P, 0 if no more
// - this version expects P^ to point to an Unicode char array
function GetNextItemCardinalW(var P: PWideChar; Sep: WideChar = ','): PtrUInt;

/// return next CSV string as double from P, 0.0 if no more
// - if Sep is #0, will return all characters until next whitespace char
function GetNextItemDouble(var P: PUTF8Char; Sep: AnsiChar = ','): double;

/// return next CSV string as currency from P, 0.0 if no more
// - if Sep is #0, will return all characters until next whitespace char
function GetNextItemCurrency(var P: PUTF8Char; Sep: AnsiChar = ','): TSynCurrency; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// return next CSV string as currency from P, 0.0 if no more
// - if Sep is #0, will return all characters until next whitespace char
procedure GetNextItemCurrency(var P: PUTF8Char; out result: TSynCurrency;
  Sep: AnsiChar = ','); overload;

/// return n-th indexed CSV string in P, starting at Index=0 for first one
function GetCSVItem(P: PUTF8Char; Index: PtrUInt; Sep: AnsiChar = ','): RawUTF8; overload;

/// return n-th indexed CSV string (unquoted if needed) in P, starting at Index=0 for first one
function GetUnQuoteCSVItem(P: PUTF8Char; Index: PtrUInt; Sep: AnsiChar = ',';
  Quote: AnsiChar = ''''): RawUTF8; overload;

/// return n-th indexed CSV string in P, starting at Index=0 for first one
// - this function return the generic string type of the compiler, and
// therefore can be used with ready to be displayed text (i.e. the VCL)
function GetCSVItemString(P: PChar; Index: PtrUInt; Sep: Char = ','): string;

/// return last CSV string in the supplied UTF-8 content
function GetLastCSVItem(const CSV: RawUTF8; Sep: AnsiChar = ','): RawUTF8;

/// return the index of a Value in a CSV string
// - start at Index=0 for first one
// - return -1 if specified Value was not found in CSV items
function FindCSVIndex(CSV: PUTF8Char; const Value: RawUTF8; Sep: AnsiChar = ',';
  CaseSensitive: boolean = true; TrimValue: boolean = false): integer;

/// add the strings in the specified CSV text into a dynamic array of UTF-8 strings
procedure CSVToRawUTF8DynArray(CSV: PUTF8Char; var Result: TRawUTF8DynArray;
  Sep: AnsiChar = ','; TrimItems: boolean = false; AddVoidItems: boolean = false); overload;

/// add the strings in the specified CSV text into a dynamic array of UTF-8 strings
procedure CSVToRawUTF8DynArray(const CSV, Sep, SepEnd: RawUTF8;
  var Result: TRawUTF8DynArray); overload;

/// return the corresponding CSV text from a dynamic array of UTF-8 strings
function RawUTF8ArrayToCSV(const Values: array of RawUTF8;
  const Sep: RawUTF8 = ','): RawUTF8;

/// return the corresponding CSV quoted text from a dynamic array of UTF-8 strings
// - apply QuoteStr() function to each Values[] item
function RawUTF8ArrayToQuotedCSV(const Values: array of RawUTF8;
  const Sep: RawUTF8 = ','; Quote: AnsiChar = ''''): RawUTF8;

/// append some prefix to all CSV values
// ! AddPrefixToCSV('One,Two,Three','Pre')='PreOne,PreTwo,PreThree'
function AddPrefixToCSV(CSV: PUTF8Char; const Prefix: RawUTF8;
  Sep: AnsiChar = ','): RawUTF8;

/// append a Value to a CSV string
procedure AddToCSV(const Value: RawUTF8; var CSV: RawUTF8; const Sep: RawUTF8 = ',');
  {$ifdef HASINLINE} inline;{$endif}

/// change a Value within a CSV string
function RenameInCSV(const OldValue, NewValue: RawUTF8; var CSV: RawUTF8;
  const Sep: RawUTF8 = ','): boolean;


{ ************ TBaseWriter parent class for Text Generation }

type
  /// event signature for TBaseWriter.OnFlushToStream callback
  TOnTextWriterFlush = procedure(Text: PUTF8Char; Len: PtrInt) of object;

  /// defines how text is to be added into TBaseWriter / TTextWriter
  // - twNone will write the supplied text with no escaping
  // - twJSONEscape will properly escape " and \ as expected by JSON
  // - twOnSameLine will convert any line feeds or control chars into spaces
  TTextWriterKind = (twNone, twJSONEscape, twOnSameLine);

  /// available global options for a TBaseWriter / TBaseWriter instance
  // - TBaseWriter.WriteObject() method behavior would be set via their own
  // TTextWriterWriteObjectOptions, and work in conjunction with those settings
  // - twoStreamIsOwned would be set if the associated TStream is owned by
  // the TBaseWriter instance
  // - twoFlushToStreamNoAutoResize would forbid FlushToStream to resize the
  // internal memory buffer when it appears undersized - FlushFinal will set it
  // before calling a last FlushToStream
  // - by default, custom serializers defined via RegisterCustomJSONSerializer()
  // would let AddRecordJSON() and AddDynArrayJSON() write enumerates and sets
  // as integer numbers, unless twoEnumSetsAsTextInRecord or
  // twoEnumSetsAsBooleanInRecord (exclusively) are set - for Mustache data
  // context, twoEnumSetsAsBooleanInRecord will return a JSON object with
  // "setname":true/false fields
  // - variants and nested objects would be serialized with their default
  // JSON serialization options, unless twoForceJSONExtended or
  // twoForceJSONStandard is defined
  // - when enumerates and sets are serialized as text into JSON, you may force
  // the identifiers to be left-trimed for all their lowercase characters
  // (e.g. sllError -> 'Error') by setting twoTrimLeftEnumSets: this option
  // would default to the global TBaseWriter.SetDefaultEnumTrim setting
  // - twoEndOfLineCRLF would reflect the TEchoWriter.EndOfLineCRLF property
  // - twoBufferIsExternal would be set if the temporary buffer is not handled
  // by the instance, but specified at constructor, maybe from the stack
  // - twoIgnoreDefaultInRecord will force custom record serialization to avoid
  // writing the fields with default values, i.e. enable soWriteIgnoreDefault
  // when TJSONCustomParserRTTI.WriteOneLevel is called
  TTextWriterOption = (
    twoStreamIsOwned,
    twoFlushToStreamNoAutoResize,
    twoEnumSetsAsTextInRecord,
    twoEnumSetsAsBooleanInRecord,
    twoFullSetsAsStar,
    twoTrimLeftEnumSets,
    twoForceJSONExtended,
    twoForceJSONStandard,
    twoEndOfLineCRLF,
    twoBufferIsExternal,
    twoIgnoreDefaultInRecord);
    
  /// options set for a TBaseWriter / TBaseWriter instance
  // - allows to override e.g. AddRecordJSON() and AddDynArrayJSON() behavior;
  // or set global process customization for a TBaseWriter
  TTextWriterOptions = set of TTextWriterOption;

  /// may be used to allocate on stack a 8KB work buffer for a TBaseWriter
  // - via the TBaseWriter.CreateOwnedStream overloaded constructor
  TTextWriterStackBuffer = array[0..8191] of AnsiChar;

  /// available options for TBaseWriter.WriteObject() method
  // - woHumanReadable will add some line feeds and indentation to the content,
  // to make it more friendly to the human eye
  // - woDontStoreDefault (which is set by default for WriteObject method) will
  // avoid serializing properties including a default value (JSONToObject function
  // will set the default values, so it may help saving some bandwidth or storage)
  // - woFullExpand will generate a debugger-friendly layout, including instance
  // class name, sets/enumerates as text, and reference pointer - as used by
  // TSynLog and ObjectToJSONFull()
  // - woStoreClassName will add a "ClassName":"TMyClass" field
  // - woStorePointer will add a "Address":"0431298A" field, and .map/.mab
  // source code line number corresponding to ESynException.RaisedAt
  // - woStoreStoredFalse will write the 'stored false' properties, even
  // if they are marked as such (used e.g. to persist all settings on file,
  // but disallow the sensitive - password - fields be logged)
  // - woHumanReadableFullSetsAsStar will store an human-readable set with
  // all its enumerates items set to be stored as ["*"]
  // - woHumanReadableEnumSetAsComment will add a comment at the end of the
  // line, containing all available values of the enumaration or set, e.g:
  // $ "Enum": "Destroying", // Idle,Started,Finished,Destroying
  // - woEnumSetsAsText will store sets and enumerables as text (is also
  // included in woFullExpand or woHumanReadable)
  // - woDateTimeWithMagic will append the JSON_SQLDATE_MAGIC (i.e. U+FFF1)
  // before the ISO-8601 encoded TDateTime value
  // - woDateTimeWithZSuffix will append the Z suffix to the ISO-8601 encoded
  // TDateTime value, to identify the content as strict UTC value
  // - TTimeLog would be serialized as Int64, unless woTimeLogAsText is defined
  // - since TSQLRecord.ID could be huge Int64 numbers, they may be truncated
  // on client side, e.g. to 53-bit range in JavaScript: you could define
  // woIDAsIDstr to append an additional "ID_str":"##########" field
  // - by default, TSQLRawBlob properties are serialized as null, unless
  // woSQLRawBlobAsBase64 is defined
  // - if woHideSensitivePersonalInformation is set, rcfSPI types (e.g. the
  // TSynPersistentWithPassword.Password field) will be serialized as "***"
  // to prevent security issues (e.g. in log)
  // - by default, TObjectList will set the woStoreClassName for its nested
  // objects, unless woObjectListWontStoreClassName is defined
  // - all inherited properties would be serialized, unless woDontStoreInherited
  // is defined, and only the topmost class level properties would be serialized
  // - woInt64AsHex will force Int64/QWord to be written as hexadecimal string -
  // see j2oAllowInt64Hex reverse option fot Json2Object
  // - woDontStoreVoid will avoid serializing numeric properties equal to 0 and
  // string properties equal to '' (replace both deprecated woDontStore0 and
  // woDontStoreEmptyString flags)
  // - woPersistentLock paranoid setting will call TSynPersistentLock.Lock/Unlock
  // during serialization
  TTextWriterWriteObjectOption = (
    woHumanReadable, woDontStoreDefault, woFullExpand,
    woStoreClassName, woStorePointer, woStoreStoredFalse,
    woHumanReadableFullSetsAsStar, woHumanReadableEnumSetAsComment,
    woEnumSetsAsText, woDateTimeWithMagic, woDateTimeWithZSuffix, woTimeLogAsText,
    woIDAsIDstr, woSQLRawBlobAsBase64, woHideSensitivePersonalInformation,
    woObjectListWontStoreClassName, woDontStoreInherited, woInt64AsHex,
    woDontStoreVoid, woPersistentLock);

  /// options set for TBaseWriter.WriteObject() method
  TTextWriterWriteObjectOptions = set of TTextWriterWriteObjectOption;

  /// the potential places were TTextWriter.AddHtmlEscape should process
  // proper HTML string escaping, unless hfNone is used
  // $  < > & "  ->   &lt; &gt; &amp; &quote;
  // by default (hfAnyWhere)
  // $  < > &  ->   &lt; &gt; &amp;
  // outside HTML attributes (hfOutsideAttributes)
  // $  & "  ->   &amp; &quote;
  // within HTML attributes (hfWithinAttributes)
  TTextWriterHTMLFormat = (
    hfNone, hfAnyWhere, hfOutsideAttributes, hfWithinAttributes);

  /// the available JSON format, for TBaseWriter.AddJSONReformat() and its
  // JSONBufferReformat() and JSONReformat() wrappers
  // - jsonCompact is the default machine-friendly single-line layout
  // - jsonHumanReadable will add line feeds and indentation, for a more
  // human-friendly result
  // - jsonUnquotedPropName will emit the jsonHumanReadable layout, but
  // with all property names being quoted only if necessary: this format
  // could be used e.g. for configuration files - this format, similar to the
  // one used in the MongoDB extended syntax, is not JSON compatible: do not
  // use it e.g. with AJAX clients, but is would be handled as expected by all
  // our units as valid JSON input, without previous correction
  // - jsonUnquotedPropNameCompact will emit single-line layout with unquoted
  // property names
  // - those features are not implemented in this unit, but in mormot.core.json
  TTextWriterJSONFormat = (
    jsonCompact,
    jsonHumanReadable,
    jsonUnquotedPropName,
    jsonUnquotedPropNameCompact);
    
  /// parent to T*Writer text processing classes, with the minimum set of methods
  // - use an internal buffer, so much faster than naive string+string
  // - see TTextWriter in mormot.core.json for proper JSON support
  // - see TJSONWriter in mormot.rest.orm.table for SQL resultset export
  // - see TJSONSerializer in mormot.core.reflection for proper class
  // serialization via WriteObject
  TBaseWriter = class
  protected
    fStream: TStream;
    fInitialStreamPosition: PtrUInt;
    fTotalFileSize: PtrUInt;
    fCustomOptions: TTextWriterOptions;
    fHumanReadableLevel: integer;
    // internal temporary buffer
    fTempBufSize: Integer;
    fTempBuf: PUTF8Char;
    fOnFlushToStream: TOnTextWriterFlush;
    function GetTextLength: PtrUInt;
    procedure SetStream(aStream: TStream);
    procedure SetBuffer(aBuf: pointer; aBufSize: integer);
  public
    /// direct access to the low-level current position in the buffer
    // - you should not use this field directly
    B: PUTF8Char;
    /// direct access to the low-level last position in the buffer
    // - you should not use this field directly
    // - points in fact to 16 bytes before the buffer ending
    BEnd: PUTF8Char;
    /// the data will be written to the specified Stream
    // - aStream may be nil: in this case, it MUST be set before using any
    // Add*() method
    // - default internal buffer size if 8192
    constructor Create(aStream: TStream; aBufSize: integer = 8192); overload;
    /// the data will be written to the specified Stream
    // - aStream may be nil: in this case, it MUST be set before using any
    // Add*() method
    // - will use an external buffer (which may be allocated on stack)
    constructor Create(aStream: TStream; aBuf: pointer; aBufSize: integer); overload;
    /// the data will be written to an internal TRawByteStringStream
    // - TRawByteStringStream.DataString method will be used by TBaseWriter.Text
    // to retrieve directly the content without any data move nor allocation
    // - default internal buffer size if 4096 (enough for most JSON objects)
    // - consider using a stack-allocated buffer and the overloaded method
    constructor CreateOwnedStream(aBufSize: integer = 4096); overload;
    /// the data will be written to an internal TRawByteStringStream
    // - will use an external buffer (which may be allocated on stack)
    // - TRawByteStringStream.DataString method will be used by TBaseWriter.Text
    // to retrieve directly the content without any data move nor allocation
    constructor CreateOwnedStream(aBuf: pointer; aBufSize: integer); overload;
    /// the data will be written to an internal TRawByteStringStream
    // - will use the stack-allocated TTextWriterStackBuffer if possible
    // - TRawByteStringStream.DataString method will be used by TBaseWriter.Text
    // to retrieve directly the content without any data move nor allocation
    constructor CreateOwnedStream(var aStackBuf: TTextWriterStackBuffer;
      aBufSize: integer = SizeOf(TTextWriterStackBuffer)); overload;
    /// the data will be written to an external file
    // - you should call explicitly FlushFinal or FlushToStream to write
    // any pending data to the file
    constructor CreateOwnedFileStream(const aFileName: TFileName;
      aBufSize: integer = 8192);
    /// release all internal structures
    // - e.g. free fStream if the instance was owned by this class
    destructor Destroy; override;
    /// allow to override the default (JSON) serialization of enumerations and
    // sets as text, which would write the whole identifier (e.g. 'sllError')
    // - calling SetDefaultEnumTrim(true) would force the enumerations to
    // be trimmed for any lower case char, e.g. sllError -> 'Error'
    // - this is global to the current process, and should be use mainly for
    // compatibility purposes for the whole process
    // - you may change the default behavior by setting twoTrimLeftEnumSets
    // in the TBaseWriter.CustomOptions property of a given serializer
    // - note that unserialization process would recognize both formats
    class procedure SetDefaultEnumTrim(aShouldTrimEnumsAsText: boolean);

    /// retrieve the data as a string
    function Text: RawUTF8;
      {$ifdef HASINLINE} inline; {$endif}
    /// retrieve the data as a string
    // - will avoid creation of a temporary RawUTF8 variable as for Text function
    procedure SetText(out result: RawUTF8; reformat: TTextWriterJSONFormat = jsonCompact);
    /// set the internal stream content with the supplied UTF-8 text
    procedure ForceContent(const text: RawUTF8);
    /// write pending data to the Stream, with automatic buffer resizal
    // - you should not have to call FlushToStream in most cases, but FlushFinal
    // at the end of the process, just before using the resulting Stream
    // - FlushToStream may be used to force immediate writing of the internal
    // memory buffer to the destination Stream
    // - you can set FlushToStreamNoAutoResize=true or call FlushFinal if you
    // do not want the automatic memory buffer resizal to take place
    function FlushToStream: PUTF8Char; virtual;
    /// write pending data to the Stream, without automatic buffer resizal
    // - will append the internal memory buffer to the Stream
    // - in short, FlushToStream may be called during the adding process, and
    // FlushFinal at the end of the process, just before using the resulting Stream
    // - if you don't call FlushToStream or FlushFinal, some pending characters
    // may not be copied to the Stream: you should call it before using the Stream
    procedure FlushFinal;

    /// append one ASCII char to the buffer
    procedure Add(c: AnsiChar); overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// append one ASCII char to the buffer, if not already there as LastChar
    procedure AddOnce(c: AnsiChar); overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// append two chars to the buffer
    procedure Add(c1,c2: AnsiChar); overload;
      {$ifdef HASINLINE} inline; {$endif}
    {$ifndef CPU64} // already implemented by Add(Value: PtrInt) method
    /// append a 64-bit signed Integer Value as text
    procedure Add(Value: Int64); overload;
    {$endif}
    /// append a 32-bit signed Integer Value as text
    procedure Add(Value: PtrInt); overload;
    /// append a boolean Value as text
    // - write either 'true' or 'false'
    procedure Add(Value: boolean); overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// append a Currency from its Int64 in-memory representation
    procedure AddCurr64(Value: PInt64); overload;
    /// append a Currency from its Int64 in-memory representation
    procedure AddCurr64(const Value: TSynCurrency); overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// append an Unsigned 32-bit Integer Value as a String
    procedure AddU(Value: cardinal);
    /// append an Unsigned 64-bit Integer Value as a String
    procedure AddQ(Value: QWord);
    /// append an Unsigned 64-bit Integer Value as a quoted hexadecimal String
    procedure AddQHex(Value: Qword);
      {$ifdef HASINLINE} inline; {$endif}
    /// append a GUID value, encoded as text without any {}
    // - will store e.g. '3F2504E0-4F89-11D3-9A0C-0305E82C3301'
    procedure Add(Value: PGUID; QuotedChar: AnsiChar = #0); overload;
    /// append a floating-point Value as a String
    // - write "Infinity", "-Infinity", and "NaN" for corresponding IEEE values
    // - noexp=true will call ExtendedToShortNoExp() to avoid any scientific
    // notation in the resulting text
    procedure AddDouble(Value: double; noexp: boolean = false);
      {$ifdef HASINLINE} inline; {$endif}
    /// append a floating-point Value as a String
    // - write "Infinity", "-Infinity", and "NaN" for corresponding IEEE values
    // - noexp=true will call ExtendedToShortNoExp() to avoid any scientific
    // notation in the resulting text
    procedure AddSingle(Value: single; noexp: boolean = false);
      {$ifdef HASINLINE} inline; {$endif}
    /// append a floating-point Value as a String
    // - write "Infinity", "-Infinity", and "NaN" for corresponding IEEE values
    // - noexp=true will call ExtendedToShortNoExp() to avoid any scientific
    // notation in the resulting text
    procedure Add(Value: Extended; precision: integer; noexp: boolean = false); overload;
    /// append a floating-point text buffer
    // - will correct on the fly '.5' -> '0.5' and '-.5' -> '-0.5'
    // - is used when the input comes from a third-party source with no regular
    // output, e.g. a database driver
    procedure AddFloatStr(P: PUTF8Char);
    /// append CR+LF (#13#10) chars
    // - this method won't call TEchoWriter.EchoAdd() registered events - use
    // TEchoWriter.AddEndOfLine() method instead
    // - TEchoWriter.AddEndOfLine() will append either CR+LF (#13#10) or
    // only LF (#10) depending on its internal options
    procedure AddCR; {$ifdef HASINLINE} inline; {$endif}
    /// append CR+LF (#13#10) chars and #9 indentation
    // - indentation depth is defined by fHumanReadableLevel protected field
    procedure AddCRAndIndent; virtual;
    /// write the same character multiple times
    procedure AddChars(aChar: AnsiChar; aCount: integer);
    /// append an Integer Value as a 2 digits text with comma
    procedure Add2(Value: PtrUInt);
    /// append an Integer Value as a 3 digits text without any comma
    procedure Add3(Value: PtrUInt);
    /// append an Integer Value as a 4 digits text with comma
    procedure Add4(Value: PtrUInt);
    /// append the current UTC date and time, in our log-friendly format
    // - e.g. append '20110325 19241502' - with no trailing space nor tab
    // - you may set LocalTime=TRUE to write the local date and time instead
    // - this method is very fast, and avoid most calculation or API calls
    procedure AddCurrentLogTime(LocalTime: boolean);
    /// append the current UTC date and time, in our log-friendly format
    // - e.g. append '19/Feb/2019:06:18:55 ' - including a trailing space
    // - you may set LocalTime=TRUE to write the local date and time instead
    // - this method is very fast, and avoid most calculation or API calls
    procedure AddCurrentNCSALogTime(LocalTime: boolean);
    /// append a time period, specified in micro seconds, in 00.000.000 TSynLog format
    procedure AddMicroSec(MS: cardinal);
    /// append some UTF-8 chars to the buffer
    // - input length is calculated from zero-ended char
    // - don't escapes chars according to the JSON RFC
    procedure AddNoJSONEscape(P: Pointer); overload;
    /// append some UTF-8 chars to the buffer
    // - don't escapes chars according to the JSON RFC
    procedure AddNoJSONEscape(P: Pointer; Len: PtrInt); overload;
    /// append some UTF-8 chars to the buffer
    // - don't escapes chars according to the JSON RFC
    procedure AddNoJSONEscapeUTF8(const text: RawByteString);
      {$ifdef HASINLINE} inline; {$endif}
    /// append some UTF-8 encoded chars to the buffer, from a generic string type
    // - don't escapes chars according to the JSON RFC
    // - if s is a UnicodeString, will convert UTF-16 into UTF-8
    procedure AddNoJSONEscapeString(const s: string);
    /// append some unicode chars to the buffer
    // - WideCharCount is the unicode chars count, not the byte size
    // - don't escapes chars according to the JSON RFC
    // - will convert the Unicode chars into UTF-8
    procedure AddNoJSONEscapeW(WideChar: PWord; WideCharCount: integer);
    /// append some Ansi text as UTF-8 chars to the buffer
    // - don't escapes chars according to the JSON RFC
    procedure AddNoJSONEscape(P: PAnsiChar; Len: PtrInt; CodePage: cardinal); overload;
    /// append some UTF-8 chars to the buffer
    // - if supplied json is '', will write 'null'
    procedure AddRawJSON(const json: RawJSON);
    /// append a line of text with CR+LF at the end
    procedure AddLine(const Text: shortstring);
    /// append some chars to the buffer in one line
    // - P should be ended with a #0
    // - will write #1..#31 chars as spaces (so content will stay on the same line)
    procedure AddOnSameLine(P: PUTF8Char); overload;
    /// append some chars to the buffer in one line
    // - will write #0..#31 chars as spaces (so content will stay on the same line)
    procedure AddOnSameLine(P: PUTF8Char; Len: PtrInt); overload;
    /// append some wide chars to the buffer in one line
    // - will write #0..#31 chars as spaces (so content will stay on the same line)
    procedure AddOnSameLineW(P: PWord; Len: PtrInt);
    /// append an UTF-8 String, with no JSON escaping
    procedure AddString(const Text: RawUTF8);
    /// append several UTF-8 strings
    procedure AddStrings(const Text: array of RawUTF8); overload;
    /// append an UTF-8 string several times
    procedure AddStrings(const Text: RawUTF8; count: integer); overload;
    /// append a ShortString
    procedure AddShort(const Text: ShortString);
    /// append a TShort8 - Text should be not '', and up to 8 chars long
    // - this method is aggressively inlined, so may be preferred to AddShort()
    // for appending simple constant UTF-8 text
    procedure AddShorter(const Text: TShort8); {$ifdef HASINLINE} inline; {$endif}
    /// append 'null' as text
    procedure AddNull; {$ifdef HASINLINE} inline; {$endif}
    /// append a sub-part of an UTF-8  String
    // - emulates AddString(copy(Text,start,len))
    procedure AddStringCopy(const Text: RawUTF8; start,len: PtrInt);
    /// append after trim first lowercase chars ('otDone' will add 'Done' e.g.)
    procedure AddTrimLeftLowerCase(Text: PShortString);
    /// append a UTF-8 String excluding any space or control char
    // - this won't escape the text as expected by JSON
    procedure AddTrimSpaces(const Text: RawUTF8); overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// append a UTF-8 String excluding any space or control char
    // - this won't escape the text as expected by JSON
    procedure AddTrimSpaces(P: PUTF8Char); overload;
    /// append some chars, replacing a given character with another
    procedure AddReplace(Text: PUTF8Char; Orig, Replaced: AnsiChar);
    /// append some chars, quoting all " chars
    // - same algorithm than AddString(QuotedStr()) - without memory allocation,
    // and with an optional maximum text length (truncated with ending '...')
    // - this function implements what is specified in the official SQLite3
    // documentation: "A string constant is formed by enclosing the string in single
    // quotes ('). A single quote within the string can be encoded by putting two
    // single quotes in a row - as in Pascal."
    procedure AddQuotedStr(Text: PUTF8Char; Quote: AnsiChar; TextMaxLen: PtrInt = 0);
    /// append some chars, escaping all HTML special chars as expected
    procedure AddHtmlEscape(Text: PUTF8Char; Fmt: TTextWriterHTMLFormat = hfAnyWhere); overload;
    /// append some chars, escaping all HTML special chars as expected
    procedure AddHtmlEscape(Text: PUTF8Char; TextLen: PtrInt;
      Fmt: TTextWriterHTMLFormat = hfAnyWhere); overload;
    /// append some chars, escaping all HTML special chars as expected
    procedure AddHtmlEscapeString(const Text: string;
      Fmt: TTextWriterHTMLFormat = hfAnyWhere);
    /// append some chars, escaping all HTML special chars as expected
    procedure AddHtmlEscapeUTF8(const Text: RawUTF8;
      Fmt: TTextWriterHTMLFormat = hfAnyWhere);
    /// append some chars, escaping all XML special chars as expected
    // - i.e.   < > & " '  as   &lt; &gt; &amp; &quote; &apos;
    // - and all control chars (i.e. #1..#31) as &#..;
    // - see @http://www.w3.org/TR/xml/#syntax
    procedure AddXmlEscape(Text: PUTF8Char);
    /// append a property name, as '"PropName":'
    // - PropName content should not need to be JSON escaped (e.g. no " within,
    // and only ASCII 7-bit characters)
    // - if twoForceJSONExtended is defined in CustomOptions, it would append
    // 'PropName:' without the double quotes
    procedure AddProp(PropName: PUTF8Char; PropNameLen: PtrInt);
    /// append a ShortString property name, as '"PropName":'
    // - PropName content should not need to be JSON escaped (e.g. no " within,
    // and only ASCII 7-bit characters)
    // - if twoForceJSONExtended is defined in CustomOptions, it would append
    // 'PropName:' without the double quotes
    // - is a wrapper around AddProp()
    procedure AddPropName(const PropName: ShortString);
      {$ifdef HASINLINE} inline; {$endif}
    /// append a RawUTF8 property name, as '"FieldName":'
    // - FieldName content should not need to be JSON escaped (e.g. no " within)
    // - if twoForceJSONExtended is defined in CustomOptions, it would append
    // 'PropName:' without the double quotes
    // - is a wrapper around AddProp()
    procedure AddFieldName(const FieldName: RawUTF8);
      {$ifdef HASINLINE} inline; {$endif}
    /// append the class name of an Object instance as text
    procedure AddClassName(aClass: TClass);
    /// append an Instance name and pointer, as '"TObjectList(00425E68)"'+SepChar
    // - append "void" if Instance = nil
    procedure AddInstanceName(Instance: TObject; SepChar: AnsiChar);
    /// append an Instance name and pointer, as 'TObjectList(00425E68)'+SepChar
    procedure AddInstancePointer(Instance: TObject; SepChar: AnsiChar;
      IncludeUnitName, IncludePointer: boolean);
    /// append some binary data as hexadecimal text conversion
    procedure AddBinToHex(Bin: Pointer; BinBytes: integer);
    /// fast conversion from binary data into hexa chars, ready to be displayed
    // - using this function with Bin^ as an integer value will serialize it
    // in big-endian order (most-significant byte first), as used by humans
    // - up to the internal buffer bytes may be converted
    procedure AddBinToHexDisplay(Bin: pointer; BinBytes: integer);
    /// fast conversion from binary data into MSB hexa chars
    // - up to the internal buffer bytes may be converted
    procedure AddBinToHexDisplayLower(Bin: pointer; BinBytes: integer;
      QuotedChar: AnsiChar = #0);
    /// fast conversion from binary data into quoted MSB lowercase hexa chars
    // - up to the internal buffer bytes may be converted
    procedure AddBinToHexDisplayQuoted(Bin: pointer; BinBytes: integer);
      {$ifdef HASINLINE} inline; {$endif}
    /// append a Value as significant hexadecimal text
    // - append its minimal size, i.e. excluding highest bytes containing 0
    // - use GetNextItemHexa() to decode such a text value
    procedure AddBinToHexDisplayMinChars(Bin: pointer; BinBytes: PtrInt;
      QuotedChar: AnsiChar = #0);
    /// add the pointer into significant hexa chars, ready to be displayed
    procedure AddPointer(P: PtrUInt; QuotedChar: AnsiChar = #0);
      {$ifdef HASINLINE} inline; {$endif}
    /// write a byte as hexa chars
    procedure AddByteToHex(Value: byte);
    /// write a Int18 value (0..262143) as 3 chars
    // - this encoding is faster than Base64, and has spaces on the left side
    // - use function Chars3ToInt18() to decode the textual content
    procedure AddInt18ToChars3(Value: cardinal);
    /// append a TTimeLog value, expanded as Iso-8601 encoded text
    procedure AddTimeLog(Value: PInt64; QuoteChar: AnsiChar = #0);
    /// append a TUnixTime value, expanded as Iso-8601 encoded text
    procedure AddUnixTime(Value: PInt64; QuoteChar: AnsiChar = #0);
    /// append a TUnixMSTime value, expanded as Iso-8601 encoded text
    procedure AddUnixMSTime(Value: PInt64; WithMS: boolean = false;
      QuoteChar: AnsiChar = #0);
    /// append a TDateTime value, expanded as Iso-8601 encoded text
    // - use 'YYYY-MM-DDThh:mm:ss' format (with FirstChar='T')
    // - if WithMS is TRUE, will append '.sss' for milliseconds resolution
    // - if QuoteChar is not #0, it will be written before and after the date
    procedure AddDateTime(Value: PDateTime; FirstChar: AnsiChar = 'T';
      QuoteChar: AnsiChar = #0; WithMS: boolean = false;
      AlwaysDateAndTime: boolean = false); overload;
    /// append a TDateTime value, expanded as Iso-8601 encoded text
    // - use 'YYYY-MM-DDThh:mm:ss' format
    // - append nothing if Value=0
    // - if WithMS is TRUE, will append '.sss' for milliseconds resolution
    procedure AddDateTime(const Value: TDateTime; WithMS: boolean = false); overload;

    /// append strings or integers with a specified format
    // - this class implementation will raise an exception for twJSONEscape,
    // and simply call FormatUTF8() over a temp RawUTF8 for twNone/twOnSameLine
    // - use faster and more complete overriden TTextWriter.Add instead!
    procedure Add(const Format: RawUTF8; const Values: array of const;
      Escape: TTextWriterKind = twNone;
      WriteObjectOptions: TTextWriterWriteObjectOptions = [woFullExpand]); overload; virtual;
    /// this class implementation will raise an exception
    // - use overriden TTextWriter version instead!
    function AddJSONReformat(JSON: PUTF8Char; Format: TTextWriterJSONFormat;
      EndOfObject: PUTF8Char): PUTF8Char; virtual;
    /// this class implementation will raise an exception
    // - use overriden TTextWriter version instead!
    procedure AddVariant(const Value: variant; Escape: TTextWriterKind = twJSONEscape;
      WriteOptions: TTextWriterWriteObjectOptions = [woFullExpand]); virtual;
    /// this class implementation will raise an exception
    // - use overriden TTextWriter version instead!
    procedure AddTypedJSON(Value, TypeInfo: pointer;
      WriteOptions: TTextWriterWriteObjectOptions = []); virtual;

    /// serialize as JSON the given object
    // - is just a wrapper around AddTypeJSON()
    procedure WriteObject(Value: TObject;
      Options: TTextWriterWriteObjectOptions = [woDontStoreDefault]);
    /// append a T*ObjArray dynamic array as a JSON array
    // - as expected by RegisterObjArrayForJSON()
    procedure AddObjArrayJSON(const aObjArray;
      aOptions: TTextWriterWriteObjectOptions = [woDontStoreDefault]);
    /// return the last char appended
    // - returns #0 if no char has been written yet
    function LastChar: AnsiChar;
    /// how many bytes are currently in the internal buffer and not on disk/stream
    // - see TextLength for the total number of bytes, on both stream and memory
    function PendingBytes: PtrUInt;
      {$ifdef HASINLINE} inline; {$endif}
    /// how many bytes were currently written on disk/stream
    // - excluding the bytes in the internal buffer (see PendingBytes)
    // - see TextLength for the total number of bytes, on both stream and memory
    property WrittenBytes: PtrUInt read fTotalFileSize;
    /// the last char appended is canceled
    // - only one char cancelation is allowed at the same position: don't call
    // CancelLastChar/CancelLastComma more than once without appending text inbetween
    procedure CancelLastChar; overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// the last char appended is canceled, if match the supplied one
    // - only one char cancelation is allowed at the same position: don't call
    // CancelLastChar/CancelLastComma more than once without appending text inbetween
    procedure CancelLastChar(aCharToCancel: AnsiChar); overload;
      {$ifdef HASINLINE} inline; {$endif}
    /// the last char appended is canceled if it was a ','
    // - only one char cancelation is allowed at the same position: don't call
    // CancelLastChar/CancelLastComma more than once without appending text inbetween
    procedure CancelLastComma;
      {$ifdef HASINLINE} inline; {$endif}
    /// rewind the Stream to the position when Create() was called
    // - note that this does not clear the Stream content itself, just
    // move back its writing position to its initial place
    procedure CancelAll;

    /// count of added bytes to the stream
    // - see PendingBytes for the number of bytes currently in the memory buffer
    // or WrittenBytes for the number of bytes already written to disk/stream
    property TextLength: PtrUInt read GetTextLength;
    /// the internal TStream used for storage
    // - you should call the FlushFinal (or FlushToStream) methods before using
    // this TStream content, to flush all pending characters
    // - if the TStream instance has not been specified when calling the
    // TBaseWriter constructor, it can be forced via this property, before
    // any writting
    property Stream: TStream read fStream write SetStream;
    /// global options to customize this TBaseWriter instance process
    // - allows to override e.g. AddRecordJSON() and AddDynArrayJSON() behavior
    property CustomOptions: TTextWriterOptions read fCustomOptions write fCustomOptions;
    /// optional event called before FlushToStream method process
    // - used e.g. by TEchoWriter to perform proper content echoing
    property OnFlushToStream: TOnTextWriterFlush read fOnFlushToStream write fOnFlushToStream;
  end;

  /// class of our simple TEXT format writer to a Stream
  TBaseWriterClass = class of TBaseWriter;

var
  /// contains the default JSON serialization class for the framework
  // - by default, TBaseWriter of this unit doesn't support WriteObject and
  // all fancy ways of JSON serialization
  // - end-user code should use this meta-class to initialize the best
  // available serializer class - e.g. TTextWriter from mormot.core.json
  DefaultTextWriterSerializer: TBaseWriterClass = TBaseWriter;

/// will serialize any TObject into its UTF-8 JSON representation
/// - serialize as JSON the published integer, Int64, floating point values,
// TDateTime (stored as ISO 8601 text), string, variant and enumerate
// (e.g. boolean) properties of the object (and its parents)
// - would set twoForceJSONStandard to force standard (non-extended) JSON
// - the enumerates properties are stored with their integer index value
// - will write also the properties published in the parent classes
// - nested properties are serialized as nested JSON objects
// - any TCollection property will also be serialized as JSON arrays
// - you can add some custom serializers for ANY Delphi class, via
// TJSONSerializer.RegisterCustomSerializer() class method
// - call internaly TBaseWriter.WriteObject() method from DefaultTextWriterSerializer
function ObjectToJSON(Value: TObject;
  Options: TTextWriterWriteObjectOptions = [woDontStoreDefault]): RawUTF8;

/// will serialize set of TObject into its UTF-8 JSON representation
// - follows ObjectToJSON()/TTextWriter.WriterObject() functions output
// - if Names is not supplied, the corresponding class names would be used
// - call internaly TBaseWriter.WriteObject() method from DefaultTextWriterSerializer
function ObjectsToJSON(const Names: array of RawUTF8; const Values: array of TObject;
  Options: TTextWriterWriteObjectOptions = [woDontStoreDefault]): RawUTF8;


type
  /// callback used to echo each line of TEchoWriter class
  // - should return TRUE on success, FALSE if the log was not echoed: but
  // TSynLog will continue logging, even if this event returned FALSE
  TOnTextWriterEcho = function(Sender: TBaseWriter; Level: TSynLogInfo;
    const Text: RawUTF8): boolean of object;

  /// add optional echoing of the lines to TBaseWriter
  // - as used e.g. by TSynLog writer for log optional redirection
  // - is defined as a sub-class to reduce plain TBaseWriter scope
  // - see SynTable.pas for SQL resultset export via TJSONWriter
  // - see mORMot.pas for proper class serialization via TJSONSerializer.WriteObject
  TEchoWriter = class
  protected
    fWriter: TBaseWriter;
    fEchoStart: PtrInt;
    fEchoBuf: RawUTF8;
    fEchos: array of TOnTextWriterEcho;
    function EchoFlush: PtrInt;
    function GetEndOfLineCRLF: boolean; {$ifdef HASINLINE}inline;{$endif}
    procedure SetEndOfLineCRLF(aEndOfLineCRLF: boolean);
  public
    /// prepare for the echoing process
    constructor Create(Owner: TBaseWriter); reintroduce;
    /// end the echoing process
    destructor Destroy; override;
    /// should be called from TBaseWriter.FlushToStream
    // - write pending data to the Stream, with automatic buffer resizal and echoing
    // - this overriden method will handle proper echoing
    procedure FlushToStream(Text: PUTF8Char; Len: PtrInt);
    /// mark an end of line, ready to be "echoed" to registered listeners
    // - append a LF (#10) char or CR+LF (#13#10) chars to the buffer, depending
    // on the EndOfLineCRLF property value (default is LF, to minimize storage)
    // - any callback registered via EchoAdd() will monitor this line
    // - used e.g. by TSynLog for console output, as stated by Level parameter
    procedure AddEndOfLine(aLevel: TSynLogInfo = sllNone);
    /// add a callback to echo each line written by this class
    // - this class expects AddEndOfLine to mark the end of each line
    procedure EchoAdd(const aEcho: TOnTextWriterEcho);
    /// remove a callback to echo each line written by this class
    // - event should have been previously registered by a EchoAdd() call
    procedure EchoRemove(const aEcho: TOnTextWriterEcho);
    /// reset the internal buffer used for echoing content
    procedure EchoReset;
    /// the associated TBaseWriter instance
    property Writer: TBaseWriter read fWriter;
    /// define how AddEndOfLine method stores its line feed characters
    // - by default (FALSE), it will append a LF (#10) char to the buffer
    // - you can set this property to TRUE, so that CR+LF (#13#10) chars will
    // be appended instead
    // - is just a wrapper around twoEndOfLineCRLF item in CustomOptions
    property EndOfLineCRLF: boolean read GetEndOfLineCRLF write SetEndOfLineCRLF;
  end;


{ ************ TRawUTF8DynArray Processing Functions }

type
  /// function prototype used internally for UTF-8 buffer comparison
  // - also used e.g. in mormot.core.variants unit
  TUTF8Compare = function(P1,P2: PUTF8Char): PtrInt;

/// returns TRUE if Value is nil or all supplied Values[] equal ''
function IsZero(const Values: TRawUTF8DynArray): boolean; overload;

/// quick helper to initialize a dynamic array of RawUTF8 from some constants
// - can be used e.g. as:
// ! MyArray := TRawUTF8DynArrayFrom(['a','b','c']);
function TRawUTF8DynArrayFrom(const Values: array of RawUTF8): TRawUTF8DynArray;

/// low-level efficient search of Value in Values[]
// - CaseSensitive=false will use StrICmp() for A..Z / a..z equivalence
function FindRawUTF8(Values: PRawUTF8; const Value: RawUTF8; ValuesCount: integer;
  CaseSensitive: boolean): integer; overload;

/// return the index of Value in Values[], -1 if not found
// - CaseSensitive=false will use StrICmp() for A..Z / a..z equivalence
function FindRawUTF8(const Values: TRawUTF8DynArray; const Value: RawUTF8;
  CaseSensitive: boolean = true): integer; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// return the index of Value in Values[], -1 if not found
// - CaseSensitive=false will use StrICmp() for A..Z / a..z equivalence
function FindRawUTF8(const Values: array of RawUTF8; const Value: RawUTF8;
  CaseSensitive: boolean = true): integer; overload;

/// return the index of Value in Values[], -1 if not found
// - here name search would use fast IdemPropNameU() function
function FindPropName(const Names: array of RawUTF8; const Name: RawUTF8): integer; overload;

/// return the index of Value in Values[] using IdemPropNameU(), -1 if not found
// - typical use with a dynamic array is like:
// ! index := FindPropName(pointer(aDynArray),length(aDynArray),aValue);
function FindPropName(Values: PRawUTF8; const Value: RawUTF8; ValuesCount: integer): integer; overload;

/// true if Value was added successfully in Values[]
function AddRawUTF8(var Values: TRawUTF8DynArray; const Value: RawUTF8;
  NoDuplicates: boolean = false; CaseSensitive: boolean = true): boolean; overload;

/// add the Value to Values[], with an external count variable, for performance
procedure AddRawUTF8(var Values: TRawUTF8DynArray; var ValuesCount: integer;
  const Value: RawUTF8); overload;

/// true if both TRawUTF8DynArray are the same
// - comparison is case-sensitive
function RawUTF8DynArrayEquals(const A, B: TRawUTF8DynArray): boolean; overload;

/// true if both TRawUTF8DynArray are the same for a given number of items
// - A and B are expected to have at least Count items
// - comparison is case-sensitive
function RawUTF8DynArrayEquals(const A, B: TRawUTF8DynArray; Count: integer): boolean; overload;

/// convert the string dynamic array into a dynamic array of UTF-8 strings
procedure StringDynArrayToRawUTF8DynArray(const Source: TStringDynArray;
  var Result: TRawUTF8DynArray);

/// convert the string list into a dynamic array of UTF-8 strings
procedure StringListToRawUTF8DynArray(Source: TStringList; var Result: TRawUTF8DynArray);

/// retrieve the index where to insert a PUTF8Char in a sorted PUTF8Char array
// - R is the last index of available entries in P^ (i.e. Count-1)
// - string comparison is case-sensitive StrComp (so will work with any PAnsiChar)
// - returns -1 if the specified Value was found (i.e. adding will duplicate a value)
// - will use fast O(log(n)) binary search algorithm
function FastLocatePUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char): PtrInt; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// retrieve the index where to insert a PUTF8Char in a sorted PUTF8Char array
// - this overloaded function accept a custom comparison function for sorting
// - R is the last index of available entries in P^ (i.e. Count-1)
// - string comparison is case-sensitive (so will work with any PAnsiChar)
// - returns -1 if the specified Value was found (i.e. adding will duplicate a value)
// - will use fast O(log(n)) binary search algorithm
function FastLocatePUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char;
  Compare: TUTF8Compare): PtrInt; overload;

/// retrieve the index where is located a PUTF8Char in a sorted PUTF8Char array
// - R is the last index of available entries in P^ (i.e. Count-1)
// - string comparison is case-sensitive StrComp (so will work with any PAnsiChar)
// - returns -1 if the specified Value was not found
// - will use inlined binary search algorithm with optimized x86_64 branchless asm
// - slightly faster than plain FastFindPUTF8CharSorted(P,R,Value,@StrComp)
function FastFindPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char): PtrInt; overload;

/// retrieve the index where is located a PUTF8Char in a sorted uppercase PUTF8Char array
// - P[] array is expected to be already uppercased
// - searched Value is converted to uppercase before search via UpperCopy255Buf(),
// so is expected to be short, i.e. length < 250
// - R is the last index of available entries in P^ (i.e. Count-1)
// - returns -1 if the specified Value was not found
// - will use fast O(log(n)) binary search algorithm
// - slightly faster than plain FastFindPUTF8CharSorted(P,R,Value,@StrIComp)
function FastFindUpperPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt;
  Value: PUTF8Char; ValueLen: PtrInt): PtrInt;

/// retrieve the index where is located a PUTF8Char in a sorted PUTF8Char array
// - R is the last index of available entries in P^ (i.e. Count-1)
// - string comparison will use the specified Compare function
// - returns -1 if the specified Value was not found
// - will use fast O(log(n)) binary search algorithm
function FastFindPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char;
  Compare: TUTF8Compare): PtrInt; overload;

/// retrieve the index of a PUTF8Char in a PUTF8Char array via a sort indexed
// - will use fast O(log(n)) binary search algorithm
function FastFindIndexedPUTF8Char(P: PPUTF8CharArray; R: PtrInt;
  var SortedIndexes: TCardinalDynArray; Value: PUTF8Char; ItemComp: TUTF8Compare): PtrInt;

/// add a RawUTF8 value in an alphaticaly sorted dynamic array of RawUTF8
// - returns the index where the Value was added successfully in Values[]
// - returns -1 if the specified Value was alredy present in Values[]
//  (we must avoid any duplicate for O(log(n)) binary search)
// - if CoValues is set, its content will be moved to allow inserting a new
// value at CoValues[result] position - a typical usage of CoValues is to store
// the corresponding ID to each RawUTF8 item
// - if FastLocatePUTF8CharSorted() has been already called, this index can
// be set to optional ForceIndex parameter
// - by default, exact (case-sensitive) match is used; you can specify a custom
// compare function if needed in Compare optional parameter
function AddSortedRawUTF8(var Values: TRawUTF8DynArray; var ValuesCount: integer;
  const Value: RawUTF8; CoValues: PIntegerDynArray = nil; ForcedIndex: PtrInt = -1;
  Compare: TUTF8Compare = nil): PtrInt;

/// delete a RawUTF8 item in a dynamic array of RawUTF8
// - if CoValues is set, the integer item at the same index is also deleted
function DeleteRawUTF8(var Values: TRawUTF8DynArray; var ValuesCount: integer;
  Index: integer; CoValues: PIntegerDynArray = nil): boolean; overload;

/// delete a RawUTF8 item in a dynamic array of RawUTF8;
function DeleteRawUTF8(var Values: TRawUTF8DynArray; Index: integer): boolean; overload;

/// sort a dynamic array of RawUTF8 items
// - if CoValues is set, the integer items are also synchronized
// - by default, exact (case-sensitive) match is used; you can specify a custom
// compare function if needed in Compare optional parameter
procedure QuickSortRawUTF8(var Values: TRawUTF8DynArray; ValuesCount: integer;
  CoValues: PIntegerDynArray = nil; Compare: TUTF8Compare = nil);


{ ************ Numbers (integers or floats) and Variants to Text Conversion }

var
  /// naive but efficient cache to avoid string memory allocation for
  // 0..999 small numbers by Int32ToUTF8/UInt32ToUTF8
  // - use around 16KB of heap (since each item consumes 16 bytes), but increase
  // overall performance and reduce memory allocation (and fragmentation),
  // especially during multi-threaded execution
  // - noticeable when strings are used as array indexes (e.g. in SynMongoDB BSON)
  // - is defined globally, since may be used from an inlined function
  SmallUInt32UTF8: array[0..999] of RawUTF8;

/// fast RawUTF8 version of 32-bit IntToStr()
function Int32ToUtf8(Value: PtrInt): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// fast RawUTF8 version of 32-bit IntToStr()
// - result as var parameter saves a local assignment and a try..finally
procedure Int32ToUTF8(Value: PtrInt; var result: RawUTF8); overload;

/// fast RawUTF8 version of 64-bit IntToStr()
function Int64ToUtf8(Value: Int64): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// fast RawUTF8 version of 64-bit IntToStr()
// - result as var parameter saves a local assignment and a try..finally
procedure Int64ToUtf8(Value: Int64; var result: RawUTF8); overload;

/// fast RawUTF8 version of 32-bit IntToStr()
function ToUTF8(Value: PtrInt): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

{$ifndef CPU64}
/// fast RawUTF8 version of 64-bit IntToStr()
function ToUTF8(Value: Int64): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}
{$endif CPU64}

/// optimized conversion of a cardinal into RawUTF8
function UInt32ToUtf8(Value: PtrUInt): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// optimized conversion of a cardinal into RawUTF8
procedure UInt32ToUtf8(Value: PtrUInt; var result: RawUTF8); overload;
  {$ifdef HASINLINE} inline; {$endif}

/// fast RawUTF8 version of 64-bit IntToStr(), with proper QWord support
procedure UInt64ToUtf8(Value: QWord; var result: RawUTF8);

/// convert a string into its INTEGER Curr64 (value*10000) representation
// - this type is compatible with Delphi currency memory map with PInt64(@Curr)^
// - fast conversion, using only integer operations
// - if NoDecimal is defined, will be set to TRUE if there is no decimal, AND
// the returned value will be an Int64 (not a PInt64(@Curr)^)
function StrToCurr64(P: PUTF8Char; NoDecimal: PBoolean = nil): Int64;

/// convert a string into its currency representation
// - will call StrToCurr64()
function StrToCurrency(P: PUTF8Char): TSynCurrency;
  {$ifdef HASINLINE} inline; {$endif}

/// convert a currency value into a string
// - fast conversion, using only integer operations
// - decimals are joined by 2 (no decimal, 2 decimals, 4 decimals)
function CurrencyToStr(const Value: TSynCurrency): RawUTF8;
  {$ifdef HASINLINE} inline; {$endif}

/// convert an INTEGER Curr64 (value*10000) into a string
// - this type is compatible with Delphi currency memory map with PInt64(@Curr)^
// - fast conversion, using only integer operations
// - decimals are joined by 2 (no decimal, 2 decimals, 4 decimals)
function Curr64ToStr(const Value: Int64): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// convert an INTEGER Curr64 (value*10000) into a string
// - this type is compatible with Delphi currency memory map with PInt64(@Curr)^
// - fast conversion, using only integer operations
// - decimals are joined by 2 (no decimal, 2 decimals, 4 decimals)
procedure Curr64ToStr(const Value: Int64; var result: RawUTF8); overload;

/// convert an INTEGER Curr64 (value*10000) into a string
// - this type is compatible with Delphi currency memory map with PInt64(@Curr)^
// - fast conversion, using only integer operations
// - decimals are joined by 2 (no decimal, 2 decimals, 4 decimals)
// - return the number of chars written to Dest^
function Curr64ToPChar(const Value: Int64; Dest: PUTF8Char): PtrInt;

/// internal fast INTEGER Curr64 (value*10000) value to text conversion
// - expect the last available temporary char position in P
// - return the last written char position (write in reverse order in P^)
// - will return 0 for Value=0, or a string representation with always 4 decimals
//   (e.g. 1->'0.0001' 500->'0.0500' 25000->'2.5000' 30000->'3.0000')
// - is called by Curr64ToPChar() and Curr64ToStr() functions
function StrCurr64(P: PAnsiChar; const Value: Int64): PAnsiChar;

/// faster than default SysUtils.IntToStr implementation
function IntToString(Value: integer): string; overload;

/// faster than default SysUtils.IntToStr implementation
function IntToString(Value: cardinal): string; overload;

/// faster than default SysUtils.IntToStr implementation
function IntToString(Value: Int64): string; overload;

/// convert a floating-point value to its numerical text equivalency
function DoubleToString(Value: Double): string;

/// convert a currency value from its Int64 binary representation into
// its numerical text equivalency
// - decimals are joined by 2 (no decimal, 2 decimals, 4 decimals)
function Curr64ToString(Value: Int64): string;

/// convert a floating-point value to its numerical text equivalency
// - on Delphi Win32, calls FloatToText() in ffGeneral mode; on FPC uses str()
// - DOUBLE_PRECISION will redirect to DoubleToShort() and its faster Fabian
// Loitsch's Grisu algorithm if available
// - returns the count of chars stored into S, i.e. length(S)
function ExtendedToShort(var S: ShortString; Value: TSynExtended; Precision: integer): integer;

/// convert a floating-point value to its numerical text equivalency without
// scientification notation
// - DOUBLE_PRECISION will redirect to DoubleToShortNoExp() and its faster Fabian
// Loitsch's Grisu algorithm if available - or calls str(Value:0:precision,S)
// - returns the count of chars stored into S, i.e. length(S)
function ExtendedToShortNoExp(var S: ShortString; Value: TSynExtended;
  Precision: integer): integer;

/// check if the supplied text is NAN/INF/+INF/-INF, i.e. not a number
// - as returned by ExtendedToShort/DoubleToShort textual conversion
// - such values do appear as IEEE floating points, but are not defined in JSON
function FloatToShortNan(const s: shortstring): TFloatNan;
  {$ifdef HASINLINE}inline;{$endif}

/// check if the supplied text is NAN/INF/+INF/-INF, i.e. not a number
// - as returned e.g. by ExtendedToStr/DoubleToStr textual conversion
// - such values do appear as IEEE floating points, but are not defined in JSON
function FloatToStrNan(const s: RawUTF8): TFloatNan;
  {$ifdef HASINLINE}inline;{$endif}

/// convert a floating-point value to its numerical text equivalency
function ExtendedToStr(Value: TSynExtended; Precision: integer): RawUTF8; overload;

/// convert a floating-point value to its numerical text equivalency
procedure ExtendedToStr(Value: TSynExtended; Precision: integer; var result: RawUTF8); overload;

/// recognize if the supplied text is NAN/INF/+INF/-INF, i.e. not a number
// - returns the number as text (stored into tmp variable), or "Infinity",
// "-Infinity", and "NaN" for corresponding IEEE special values
// - result is a PShortString either over tmp, or JSON_NAN[]
function FloatToJSONNan(const s: ShortString): PShortString;
  {$ifdef HASINLINE}inline;{$endif}

/// convert a floating-point value to its JSON text equivalency
// - depending on the platform, it may either call str() or FloatToText()
// in ffGeneral mode (the shortest possible decimal string using fixed or
// scientific format)
// - returns the number as text (stored into tmp variable), or "Infinity",
// "-Infinity", and "NaN" for corresponding IEEE special values
// - result is a PShortString either over tmp, or JSON_NAN[]
function ExtendedToJSON(var tmp: ShortString; Value: TSynExtended;
  Precision: integer; NoExp: boolean): PShortString;

/// convert a 64-bit floating-point value to its numerical text equivalency
// - on Delphi Win32, calls FloatToText() in ffGeneral mode
// - on other platforms, i.e. Delphi Win64 and all FPC targets, will use our own
// faster Fabian Loitsch's Grisu algorithm implementation
// - returns the count of chars stored into S, i.e. length(S)
function DoubleToShort(var S: ShortString; const Value: double): integer;
  {$ifdef FPC}inline;{$endif}

/// convert a 64-bit floating-point value to its numerical text equivalency
// without scientific notation
// - on Delphi Win32, calls FloatToText() in ffGeneral mode
// - on other platforms, i.e. Delphi Win64 and all FPC targets, will use our own
// faster Fabian Loitsch's Grisu algorithm implementation
// - returns the count of chars stored into S, i.e. length(S)
function DoubleToShortNoExp(var S: ShortString; const Value: double): integer;
  {$ifdef FPC}inline;{$endif}

{$ifdef DOUBLETOSHORT_USEGRISU}
const
  // special text returned if the double is not a number
  C_STR_INF: string[3] = 'Inf';
  C_STR_QNAN: string[3] = 'Nan';

  // min_width parameter special value, as used internally by FPC for str(d,s)
  // - DoubleToAscii() only accept C_NO_MIN_WIDTH or 0 for min_width: space
  // trailing has been removed in this cut-down version
  C_NO_MIN_WIDTH = -32767;

/// raw function to convert a 64-bit double into a shortstring, stored in str
// - implements Fabian Loitsch's Grisu algorithm dedicated to double values
// - currently, this unit only set min_width=0 (for DoubleToShortNoExp to avoid
// any scientific notation ) or min_width=C_NO_MIN_WIDTH (for DoubleToShort to
// force the scientific notation when the double cannot be represented as
// a simple fractinal number)
procedure DoubleToAscii(min_width, frac_digits: integer; const v: double; str: PAnsiChar);
{$endif DOUBLETOSHORT_USEGRISU}

/// convert a 64-bit floating-point value to its JSON text equivalency
// - on Delphi Win32, calls FloatToText() in ffGeneral mode
// - on other platforms, i.e. Delphi Win64 and all FPC targets, will use our own
// faster Fabian Loitsch's Grisu algorithm
// - returns the number as text (stored into tmp variable), or "Infinity",
// "-Infinity", and "NaN" for corresponding IEEE special values
// - result is a PShortString either over tmp, or JSON_NAN[]
function DoubleToJSON(var tmp: ShortString; Value: double; NoExp: boolean): PShortString;

/// convert a 64-bit floating-point value to its numerical text equivalency
function DoubleToStr(Value: Double): RawUTF8; overload;
  {$ifdef HASINLINE}inline;{$endif}

/// convert a 64-bit floating-point value to its numerical text equivalency
procedure DoubleToStr(Value: Double; var result: RawUTF8); overload;

/// copy a floating-point text buffer with proper correction and validation
// - will correct on the fly '.5' -> '0.5' and '-.5' -> '-0.5'
// - will end not only on #0 but on any char not matching 1[.2[e[-]3]] pattern
// - is used when the input comes from a third-party source with no regular
// output, e.g. a database driver, via TBaseWriter.AddFloatStr
function FloatStrCopy(s, d: PUTF8Char): PUTF8Char;

/// fast conversion of 2 digit characters into a 0..99 value
// - returns FALSE on success, TRUE if P^ is not correct
function Char2ToByte(P: PUTF8Char; out Value: Cardinal;
   ConvertHexToBinTab: PByteArray): Boolean;
  {$ifdef HASINLINE} inline;{$endif}

/// fast conversion of 3 digit characters into a 0..9999 value
// - returns FALSE on success, TRUE if P^ is not correct
function Char3ToWord(P: PUTF8Char; out Value: Cardinal;
   ConvertHexToBinTab: PByteArray): Boolean;
  {$ifdef HASINLINE} inline;{$endif}

/// fast conversion of 4 digit characters into a 0..9999 value
// - returns FALSE on success, TRUE if P^ is not correct
function Char4ToWord(P: PUTF8Char; out Value: Cardinal;
   ConvertHexToBinTab: PByteArray): Boolean;
  {$ifdef HASINLINE} inline;{$endif}


/// convert any Variant into UTF-8 encoded String
// - use VariantSaveJSON() instead if you need a conversion to JSON with
// custom parameters
// - note: null will be returned as 'null'
function VariantToUTF8(const V: Variant): RawUTF8; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// convert any Variant into UTF-8 encoded String
// - use VariantSaveJSON() instead if you need a conversion to JSON with
// custom parameters
// - note: null will be returned as 'null'
function ToUTF8(const V: Variant): RawUTF8; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// convert any Variant into UTF-8 encoded String
// - use VariantSaveJSON() instead if you need a conversion to JSON with
// custom parameters
// - wasString is set if the V value was a text
// - empty and null variants will be stored as 'null' text - as expected by JSON
// - custom variant types (e.g. TDocVariant) will be stored as JSON
procedure VariantToUTF8(const V: Variant; var result: RawUTF8; var wasString: boolean); overload;

/// convert any Variant into UTF-8 encoded String
// - use VariantSaveJSON() instead if you need a conversion to JSON with
// custom parameters
// - returns TRUE if the V value was a text, FALSE if was not (e.g. a number)
// - empty and null variants will be stored as 'null' text - as expected by JSON
// - custom variant types (e.g. TDocVariant) will be stored as JSON
function VariantToUTF8(const V: Variant; var Text: RawUTF8): boolean; overload;

/// save a variant value into a JSON content
// - is properly implemented by mormot.core.json.pas: if this unit is not
// included in the project, this function will raise an exception
// - follows the TBaseWriter.AddVariant() and VariantLoadJSON() format
// - is able to handle simple and custom variant types, for instance:
// !  VariantSaveJSON(1.5)='1.5'
// !  VariantSaveJSON('test')='"test"'
// !  o := _Json('{ BSON: [ "test", 5.05, 1986 ] }');
// !  VariantSaveJSON(o)='{"BSON":["test",5.05,1986]}'
// !  o := _Obj(['name','John','doc',_Obj(['one',1,'two',_Arr(['one',2])])]);
// !  VariantSaveJSON(o)='{"name":"John","doc":{"one":1,"two":["one",2]}}'
// - note that before Delphi 2009, any varString value is expected to be
// a RawUTF8 instance - which does make sense in the mORMot area
procedure VariantSaveJSON(const Value: variant; Escape: TTextWriterKind;
  var result: RawUTF8); overload;

/// save a variant value into a JSON content
// - just a wrapper around the overloaded procedure
function VariantSaveJSON(const Value: variant;
  Escape: TTextWriterKind = twJSONEscape): RawUTF8; overload;

var
  /// unserialize a JSON content into a variant
  // - is properly implemented by mormot.core.json.pas: if this unit is not
  // included in the project, this function is nil
  // - used by mormot.core.data.pas RTTI_BINARYLOAD[tkVariant]() for complex types
  BinaryVariantLoadAsJSON: procedure(var Value: variant; JSON: PUTF8Char);


type
  /// used e.g. by UInt4DigitsToShort/UInt3DigitsToShort/UInt2DigitsToShort
  // - such result type would avoid a string allocation on heap
  TShort4 = string[4];

/// creates a 4 digits short string from a 0..9999 value
// - using TShort4 as returned string would avoid a string allocation on heap
// - could be used e.g. as parameter to FormatUTF8()
function UInt4DigitsToShort(Value: Cardinal): TShort4;
  {$ifdef HASINLINE} inline; {$endif}

/// creates a 3 digits short string from a 0..999 value
// - using TShort4 as returned string would avoid a string allocation on heap
// - could be used e.g. as parameter to FormatUTF8()
function UInt3DigitsToShort(Value: Cardinal): TShort4;
  {$ifdef HASINLINE} inline; {$endif}

/// creates a 2 digits short string from a 0..99 value
// - using TShort4 as returned string would avoid a string allocation on heap
// - could be used e.g. as parameter to FormatUTF8()
function UInt2DigitsToShort(Value: byte): TShort4;
  {$ifdef HASINLINE} inline; {$endif}

/// creates a 2 digits short string from a 0..99 value
// - won't test Value>99 as UInt2DigitsToShort()
function UInt2DigitsToShortFast(Value: byte): TShort4;
  {$ifdef HASINLINE} inline; {$endif}


{ ************ Text Formatting functions }

/// convert an open array (const Args: array of const) argument to an UTF-8
// encoded text
// - note that, due to a Delphi compiler limitation, cardinal values should be
// type-casted to Int64() (otherwise the integer mapped value will be converted)
// - any supplied TObject instance will be written as their class name
procedure VarRecToUTF8(const V: TVarRec; var result: RawUTF8;
  wasString: PBoolean = nil);

type
  /// a memory structure which avoids a temporary RawUTF8 allocation
  // - used by VarRecToTempUTF8() and FormatUTF8()/FormatShort()
  TTempUTF8 = record
    Len: PtrInt;
    Text: PUTF8Char;
    TempRawUTF8: pointer;
    Temp: array[0..23] of AnsiChar;
  end;
  PTempUTF8 = ^TTempUTF8;

/// convert an open array (const Args: array of const) argument to an UTF-8
// encoded text, using a specified temporary buffer
// - this function would allocate a RawUTF8 in TempRawUTF8 only if needed,
// but use the supplied Res.Temp[] buffer for numbers to text conversion -
// caller should ensure to make RawUTF8(TempRawUTF8) := '' on the entry
// - it would return the number of UTF-8 bytes, i.e. Res.Len
// - note that, due to a Delphi compiler limitation, cardinal values should be
// type-casted to Int64() (otherwise the integer mapped value will be converted)
// - any supplied TObject instance will be written as their class name
function VarRecToTempUTF8(const V: TVarRec; var Res: TTempUTF8): integer;

/// convert an open array (const Args: array of const) argument to an UTF-8
// encoded text, returning FALSE if the argument was not a string value
function VarRecToUTF8IsString(const V: TVarRec; var value: RawUTF8): boolean;
  {$ifdef HASINLINE} inline; {$endif}

/// convert an open array (const Args: array of const) argument to an Int64
// - returns TRUE and set Value if the supplied argument is a vtInteger, vtInt64
// or vtBoolean
// - returns FALSE if the argument is not an integer
// - note that, due to a Delphi compiler limitation, cardinal values should be
// type-casted to Int64() (otherwise the integer mapped value will be converted)
function VarRecToInt64(const V: TVarRec; out value: Int64): boolean;

/// convert an open array (const Args: array of const) argument to a floating
// point value
// - returns TRUE and set Value if the supplied argument is a number (e.g.
// vtInteger, vtInt64, vtCurrency or vtExtended)
// - returns FALSE if the argument is not a number
// - note that, due to a Delphi compiler limitation, cardinal values should be
// type-casted to Int64() (otherwise the integer mapped value will be converted)
function VarRecToDouble(const V: TVarRec; out value: double): boolean;

/// convert an open array (const Args: array of const) argument to a value
// encoded as with :(...): inlined parameters in FormatUTF8(Format,Args,Params)
// - note that, due to a Delphi compiler limitation, cardinal values should be
// type-casted to Int64() (otherwise the integer mapped value will be converted)
// - any supplied TObject instance will be written as their class name
procedure VarRecToInlineValue(const V: TVarRec; var result: RawUTF8);

/// get an open array (const Args: array of const) character argument
// - only handle varChar and varWideChar kind of arguments
function VarRecAsChar(const V: TVarRec): integer;
  {$ifdef HASINLINE} inline; {$endif}

/// fast Format() function replacement, optimized for RawUTF8
// - only supported token is %, which will be written in the resulting string
// according to each Args[] supplied items - so you will never get any exception
// as with the SysUtils.Format() when a specifier is incorrect
// - resulting string has no length limit and uses fast concatenation
// - there is no escape char, so to output a '%' character, you need to use '%'
// as place-holder, and specify '%' as value in the Args array
// - note that, due to a Delphi compiler limitation, cardinal values should be
// type-casted to Int64() (otherwise the integer mapped value will be converted)
// - any supplied TObject instance will be written as their class name
function FormatUTF8(const Format: RawUTF8; const Args: array of const): RawUTF8; overload;

/// fast Format() function replacement, optimized for RawUTF8
// - overloaded function, which avoid a temporary RawUTF8 instance on stack
procedure FormatUTF8(const Format: RawUTF8; const Args: array of const;
  out result: RawUTF8); overload;

/// fast Format() function replacement, tuned for direct memory buffer write
// - use the same single token % (and implementation) than FormatUTF8()
// - returns the number of UTF-8 bytes appended to Dest^
function FormatBuffer(const Format: RawUTF8; const Args: array of const;
  Dest: pointer; DestLen: PtrInt): PtrInt;

/// fast Format() function replacement, for UTF-8 content stored in shortstring
// - use the same single token % (and implementation) than FormatUTF8()
// - shortstring allows fast stack allocation, so is perfect for small content
// - truncate result if the text size exceeds 255 bytes
procedure FormatShort(const Format: RawUTF8; const Args: array of const;
  var result: shortstring);

/// fast Format() function replacement, for UTF-8 content stored in shortstring
function FormatToShort(const Format: RawUTF8; const Args: array of const): shortstring;

/// fast Format() function replacement, tuned for small content
// - use the same single token % (and implementation) than FormatUTF8()
procedure FormatString(const Format: RawUTF8; const Args: array of const;
  out result: string); overload;

/// fast Format() function replacement, tuned for small content
// - use the same single token % (and implementation) than FormatUTF8()
function FormatString(const Format: RawUTF8; const Args: array of const): string; overload;
  {$ifdef FPC}inline;{$endif}

/// fast Format() function replacement, for UTF-8 content stored in TShort16
// - truncate result if the text size exceeds 16 bytes
procedure FormatShort16(const Format: RawUTF8; const Args: array of const;
  var result: TShort16);

/// direct conversion of a VCL string into a console OEM-encoded String
// - under Windows, will use the CP_OEMCP encoding
// - under Linux, will expect the console to be defined with UTF-8 encoding
function StringToConsole(const S: string): RawByteString;

/// write some text to the console using a given color
procedure ConsoleWrite(const Fmt: RawUTF8; const Args: array of const;
  Color: TConsoleColor = ccLightGray; NoLineFeed: boolean = false); overload;

/// could be used in the main program block of a console application to
// handle unexpected fatal exceptions
// - WaitForEnterKey=true won't do anything on POSIX (to avoid locking a daemon)
// - typical use may be:
// !begin
// !  try
// !    ... // main console process
// !  except
// !    on E: Exception do
// !      ConsoleShowFatalException(E);
// !  end;
// !end.
procedure ConsoleShowFatalException(E: Exception; WaitForEnterKey: boolean = true);


{ ************ Resource and Time Functions }

/// convert a size to a human readable value power-of-two metric value
// - append EB, PB, TB, GB, MB, KB or B symbol with or without preceding space
// - for EB, PB, TB, GB, MB and KB, add one fractional digit
procedure KB(bytes: Int64; out result: TShort16; nospace: boolean); overload;

/// convert a size to a human readable value
// - append EB, PB, TB, GB, MB, KB or B symbol with preceding space
// - for EB, PB, TB, GB, MB and KB, add one fractional digit
function KB(bytes: Int64): TShort16; overload;
  {$ifdef FPC_OR_UNICODE}inline;{$endif} // Delphi 2007 is buggy as hell

/// convert a size to a human readable value
// - append EB, PB, TB, GB, MB, KB or B symbol without preceding space
// - for EB, PB, TB, GB, MB and KB, add one fractional digit
function KBNoSpace(bytes: Int64): TShort16;
  {$ifdef FPC_OR_UNICODE}inline;{$endif} // Delphi 2007 is buggy as hell

/// convert a size to a human readable value
// - append EB, PB, TB, GB, MB, KB or B symbol with or without preceding space
// - for EB, PB, TB, GB, MB and KB, add one fractional digit
function KB(bytes: Int64; nospace: boolean): TShort16; overload;
  {$ifdef FPC_OR_UNICODE}inline;{$endif} // Delphi 2007 is buggy as hell

/// convert a string size to a human readable value
// - append EB, PB, TB, GB, MB, KB or B symbol
// - for EB, PB, TB, GB, MB and KB, add one fractional digit
function KB(const buffer: RawByteString): TShort16; overload;
  {$ifdef FPC_OR_UNICODE}inline;{$endif}

/// convert a size to a human readable value
// - append EB, PB, TB, GB, MB, KB or B symbol
// - for EB, PB, TB, GB, MB and KB, add one fractional digit
procedure KBU(bytes: Int64; var result: RawUTF8);

/// convert a count to a human readable value power-of-two metric value
// - append E, P, T, G, M, K symbol, with one fractional digit
procedure K(value: Int64; out result: TShort16); overload;

  /// convert a count to a human readable value power-of-two metric value
  // - append E, P, T, G, M, K symbol, with one fractional digit
function K(value: Int64): TShort16; overload;
  {$ifdef FPC_OR_UNICODE}inline;{$endif} // Delphi 2007 is buggy as hell

/// convert a micro seconds elapsed time into a human readable value
// - append 'us', 'ms', 's', 'm', 'h' and 'd' symbol for the given value range,
// with two fractional digits
function MicroSecToString(Micro: QWord): TShort16; overload;
  {$ifdef FPC_OR_UNICODE}inline;{$endif} // Delphi 2007 is buggy as hell

/// convert a micro seconds elapsed time into a human readable value
// - append 'us', 'ms', 's', 'm', 'h' and 'd' symbol for the given value range,
// with two fractional digits
procedure MicroSecToString(Micro: QWord; out result: TShort16); overload;

/// convert an integer value into its textual representation with thousands marked
// - ThousandSep is the character used to separate thousands in numbers with
// more than three digits to the left of the decimal separator
function IntToThousandString(Value: integer; const ThousandSep: TShort4=','): shortstring;


{ ************ ESynException class }

{$ifndef NOEXCEPTIONINTERCEPT}

type
  /// global hook callback to customize exceptions logged by TSynLog
  // - should return TRUE if all needed information has been logged by the
  // event handler
  // - should return FALSE if Context.EAddr and Stack trace is to be appended
  TSynLogExceptionToStr = function(WR: TBaseWriter;
    const Context: TSynLogExceptionContext): boolean;

var
  /// allow to customize the ESynException logging message
  TSynLogExceptionToStrCustom: TSynLogExceptionToStr = nil;

/// the default Exception handler for logging
// - defined here to be called e.g. by ESynException.CustomLog() as default
function DefaultSynLogExceptionToStr(WR: TBaseWriter;
  const Context: TSynLogExceptionContext): boolean;

{$endif NOEXCEPTIONINTERCEPT}


type
  {$M+}
  /// generic parent class of all custom Exception types of this unit
  // - all our classes inheriting from ESynException are serializable,
  // so you could use ObjectToJSONDebug(anyESynException) to retrieve some
  // extended information
  ESynException = class(Exception)
  protected
    fRaisedAt: pointer;
  public
    /// constructor which will use FormatUTF8() instead of Format()
    // - expect % as delimiter, so is less error prone than %s %d %g
    // - will handle vtPointer/vtClass/vtObject/vtVariant kind of arguments,
    // appending class name for any class or object, the hexa value for a
    // pointer, or the JSON representation of any supplied TDocVariant
    constructor CreateUTF8(const Format: RawUTF8; const Args: array of const);
    /// constructor appending some FormatUTF8() content to the GetLastError
    // - message will contain GetLastError value followed by the formatted text
    // - expect % as delimiter, so is less error prone than %s %d %g
    // - will handle vtPointer/vtClass/vtObject/vtVariant kind of arguments,
    // appending class name for any class or object, the hexa value for a
    // pointer, or the JSON representation of any supplied TDocVariant
    constructor CreateLastOSError(const Format: RawUTF8; const Args: array of const);
    {$ifndef NOEXCEPTIONINTERCEPT}
    /// can be used to customize how the exception is logged
    // - this default implementation will call the TSynLogExceptionToStrCustom
    // global callback, if defined, or a default handler internal to this unit
    // - override this method to provide a custom logging content
    // - should return TRUE if Context.EAddr and Stack trace is not to be
    // written (i.e. as for any TSynLogExceptionToStr callback)
    function CustomLog(WR: TBaseWriter;
      const Context: TSynLogExceptionContext): boolean; virtual;
    {$endif NOEXCEPTIONINTERCEPT}
    /// the code location when this exception was triggered
    // - populated by SynLog unit, during interception - so may be nil
    // - you can use TSynMapFile.FindLocation(ESynException) class function to
    // guess the corresponding source code line
    // - will be serialized as "Address": hexadecimal and source code location
    // (using TSynMapFile .map/.mab information) in TJSONSerializer.WriteObject
    // when woStorePointer option is defined - e.g. with ObjectToJSONDebug()
    property RaisedAt: pointer read fRaisedAt write fRaisedAt;
  published
    /// the Exception Message string, as defined in parent Exception class
    property Message;
  end;
  {$M-}

  /// meta-class of the ESynException hierarchy
  ESynExceptionClass = class of ESynException;


{ **************** Hexadecimal Text And Binary Conversion }

var
  /// a conversion table from hexa chars into binary data
  // - returns 255 for any character out of 0..9,A..Z,a..z range
  // - used e.g. by HexToBin() function
  // - is defined globally, since may be used from an inlined function
  ConvertHexToBin: TNormTableByte;

type
  TAnsiCharToByte = array[AnsiChar] of byte;
  TAnsiCharToWord = array[AnsiChar] of word;
  TByteToWord = array[byte] of word;

var
  /// fast lookup table for converting hexadecimal numbers from 0 to 15
  // into their ASCII equivalence
  // - is local for better code generation
  TwoDigitsHex: array[byte] of array[1..2] of AnsiChar;
  TwoDigitsHexW: TAnsiCharToWord absolute TwoDigitsHex;
  TwoDigitsHexWB: array[byte] of word absolute TwoDigitsHex;
  /// lowercase hexadecimal lookup table
  TwoDigitsHexLower: array[byte] of array[1..2] of AnsiChar;
  TwoDigitsHexWLower: TAnsiCharToWord absolute TwoDigitsHexLower;
  TwoDigitsHexWBLower: array[byte] of word absolute TwoDigitsHexLower;

/// fast conversion from hexa chars into binary data
// - BinBytes contain the bytes count to be converted: Hex^ must contain
//  at least BinBytes*2 chars to be converted, and Bin^ enough space
// - if Bin=nil, no output data is written, but the Hex^ format is checked
// - return false if any invalid (non hexa) char is found in Hex^
// - using this function with Bin^ as an integer value will decode in big-endian
// order (most-signignifican byte first)
function HexToBin(Hex: PAnsiChar; Bin: PByte; BinBytes: Integer): boolean; overload;

/// fast conversion with no validity check from hexa chars into binary data
procedure HexToBinFast(Hex: PAnsiChar; Bin: PByte; BinBytes: Integer);

/// fast conversion from one hexa char pair into a 8 bit AnsiChar
// - return false if any invalid (non hexa) char is found in Hex^
// - similar to HexToBin(Hex,nil,1)
function HexToCharValid(Hex: PAnsiChar): boolean;
  {$ifdef HASINLINE} inline; {$endif}

/// fast check if the supplied Hex buffer is an hexadecimal representation
// of a binary buffer of a given number of bytes
function IsHex(const Hex: RawByteString; BinBytes: integer): boolean;

/// fast conversion from one hexa char pair into a 8 bit AnsiChar
// - return false if any invalid (non hexa) char is found in Hex^
// - similar to HexToBin(Hex,Bin,1) but with Bin<>nil
// - use HexToCharValid if you want to check a hexadecimal char content
function HexToChar(Hex: PAnsiChar; Bin: PUTF8Char): boolean;
  {$ifdef HASINLINE} inline; {$endif}

/// fast conversion from two hexa bytes into a 16 bit UTF-16 WideChar
// - similar to HexToBin(Hex,@wordvar,2) + bswap(wordvar)
function HexToWideChar(Hex: PAnsiChar): cardinal;
  {$ifdef HASINLINE} inline; {$endif}

/// fast conversion from binary data into hexa chars
// - BinBytes contain the bytes count to be converted: Hex^ must contain
// enough space for at least BinBytes*2 chars
// - using this function with BinBytes^ as an integer value will encode it
// in low-endian order (less-signignifican byte first): don't use it for display
procedure BinToHex(Bin, Hex: PAnsiChar; BinBytes: integer); overload;

/// fast conversion from hexa chars into binary data
function HexToBin(const Hex: RawUTF8): RawByteString; overload;

/// fast conversion from binary data into hexa chars
function BinToHex(const Bin: RawByteString): RawUTF8; overload;

/// fast conversion from binary data into hexa chars
function BinToHex(Bin: PAnsiChar; BinBytes: integer): RawUTF8; overload;

/// fast conversion from binary data into hexa chars, ready to be displayed
// - BinBytes contain the bytes count to be converted: Hex^ must contain
// enough space for at least BinBytes*2 chars
// - using this function with Bin^ as an integer value will encode it
// in big-endian order (most-signignifican byte first): use it for display
procedure BinToHexDisplay(Bin, Hex: PAnsiChar; BinBytes: integer); overload;

/// fast conversion from binary data into hexa chars, ready to be displayed
function BinToHexDisplay(Bin: PAnsiChar; BinBytes: integer): RawUTF8; overload;

/// fast conversion from binary data into lowercase hexa chars
// - BinBytes contain the bytes count to be converted: Hex^ must contain
// enough space for at least BinBytes*2 chars
// - using this function with BinBytes^ as an integer value will encode it
// in low-endian order (less-signignifican byte first): don't use it for display
procedure BinToHexLower(Bin, Hex: PAnsiChar; BinBytes: integer); overload;

/// fast conversion from binary data into lowercase hexa chars
function BinToHexLower(const Bin: RawByteString): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// fast conversion from binary data into lowercase hexa chars
function BinToHexLower(Bin: PAnsiChar; BinBytes: integer): RawUTF8; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// fast conversion from binary data into lowercase hexa chars
procedure BinToHexLower(Bin: PAnsiChar; BinBytes: integer; var result: RawUTF8); overload;

/// fast conversion from binary data into lowercase hexa chars
// - BinBytes contain the bytes count to be converted: Hex^ must contain
// enough space for at least BinBytes*2 chars
// - using this function with Bin^ as an integer value will encode it
// in big-endian order (most-signignifican byte first): use it for display
procedure BinToHexDisplayLower(Bin, Hex: PAnsiChar; BinBytes: PtrInt); overload;

/// fast conversion from binary data into lowercase hexa chars
function BinToHexDisplayLower(Bin: PAnsiChar; BinBytes: integer): RawUTF8; overload;

/// fast conversion from up to 127 bytes of binary data into lowercase hexa chars
function BinToHexDisplayLowerShort(Bin: PAnsiChar; BinBytes: integer): shortstring;

/// fast conversion from up to 64-bit of binary data into lowercase hexa chars
function BinToHexDisplayLowerShort16(Bin: Int64; BinBytes: integer): TShort16;

/// fast conversion from binary data into hexa lowercase chars, ready to be
// used as a convenient TFileName prefix
function BinToHexDisplayFile(Bin: PAnsiChar; BinBytes: integer): TFileName;

/// append one byte as hexadecimal char pairs, into a text buffer
function ByteToHex(P: PAnsiChar; Value: byte): PAnsiChar;
  {$ifdef HASINLINE} inline; {$endif}

/// fast conversion from a pointer data into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
function PointerToHex(aPointer: Pointer): RawUTF8; overload;

/// fast conversion from a pointer data into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
procedure PointerToHex(aPointer: Pointer; var result: RawUTF8); overload;

/// fast conversion from a pointer data into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - such result type would avoid a string allocation on heap
function PointerToHexShort(aPointer: Pointer): TShort16; overload;

/// fast conversion from a Cardinal value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - reverse function of HexDisplayToCardinal()
function CardinalToHex(aCardinal: Cardinal): RawUTF8;

/// fast conversion from a Cardinal value into hexa chars, ready to be displayed
// - use internally BinToHexDisplayLower()
// - reverse function of HexDisplayToCardinal()
function CardinalToHexLower(aCardinal: Cardinal): RawUTF8;

/// fast conversion from a Cardinal value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - such result type would avoid a string allocation on heap
function CardinalToHexShort(aCardinal: Cardinal): TShort16;

/// fast conversion from a Int64 value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - reverse function of HexDisplayToInt64()
function Int64ToHex(aInt64: Int64): RawUTF8; overload;

/// fast conversion from a Int64 value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - reverse function of HexDisplayToInt64()
procedure Int64ToHex(aInt64: Int64; var result: RawUTF8); overload;

/// fast conversion from a Int64 value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - such result type would avoid a string allocation on heap
procedure Int64ToHexShort(aInt64: Int64; out result: TShort16); overload;

/// fast conversion from a Int64 value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - such result type would avoid a string allocation on heap
function Int64ToHexShort(aInt64: Int64): TShort16; overload;

/// fast conversion from a Int64 value into hexa chars, ready to be displayed
// - use internally BinToHexDisplay()
// - reverse function of HexDisplayToInt64()
function Int64ToHexString(aInt64: Int64): string;

/// fast conversion from hexa chars in reverse order into a binary buffer
function HexDisplayToBin(Hex: PAnsiChar; Bin: PByte; BinBytes: integer): boolean;

/// fast conversion from hexa chars in reverse order into a cardinal
// - reverse function of CardinalToHex()
// - returns false and set aValue=0 if Hex is not a valid hexadecimal 32-bit
// unsigned integer
// - returns true and set aValue with the decoded number, on success
function HexDisplayToCardinal(Hex: PAnsiChar; out aValue: cardinal): boolean;
  {$ifndef FPC}{$ifdef HASINLINE} inline; {$endif}{$endif}
  // inline gives an error under release conditions with (old?) FPC

/// fast conversion from hexa chars in reverse order into a cardinal
// - reverse function of Int64ToHex()
// - returns false and set aValue=0 if Hex is not a valid hexadecimal 64-bit
// signed integer
// - returns true and set aValue with the decoded number, on success
function HexDisplayToInt64(Hex: PAnsiChar; out aValue: Int64): boolean; overload;
    {$ifndef FPC}{$ifdef HASINLINE} inline; {$endif}{$endif}
    { inline gives an error under release conditions with FPC }

/// fast conversion from hexa chars in reverse order into a cardinal
// - reverse function of Int64ToHex()
// - returns 0 if the supplied text buffer is not a valid hexadecimal 64-bit
// signed integer
function HexDisplayToInt64(const Hex: RawByteString): Int64; overload;
  {$ifdef HASINLINE} inline; {$endif}

/// revert the value as encoded by TBaseWriter.AddInt18ToChars3() or Int18ToChars3()
// - no range check is performed: you should ensure that the incoming text
// follows the expected 3-chars layout
function Chars3ToInt18(P: pointer): cardinal;
  {$ifdef HASINLINE}inline;{$endif}

/// compute the value as encoded by TBaseWriter.AddInt18ToChars3() method
function Int18ToChars3(Value: cardinal): RawUTF8; overload;

/// compute the value as encoded by TBaseWriter.AddInt18ToChars3() method
procedure Int18ToChars3(Value: cardinal; var result: RawUTF8); overload;

/// convert a 32-bit integer (storing a IP4 address) into its full notation
// - returns e.g. '1.2.3.4' for any valid address, or '' if ip4=0
function IP4Text(ip4: cardinal): shortstring; overload;

/// convert a 128-bit buffer (storing an IP6 address) into its full notation
// - returns e.g. '2001:0db8:0a0b:12f0:0000:0000:0000:0001'
function IP6Text(ip6: PHash128): shortstring; overload; {$ifdef HASINLINE} inline;{$endif}

/// convert a 128-bit buffer (storing an IP6 address) into its full notation
// - returns e.g. '2001:0db8:0a0b:12f0:0000:0000:0000:0001'
procedure IP6Text(ip6: PHash128; result: PShortString); overload;

/// convert an IPv4 'x.x.x.x' text into its 32-bit value
// - returns TRUE if the text was a valid IPv4 text, unserialized as 32-bit aValue
// - returns FALSE on parsing error, also setting aValue=0
// - '' or '127.0.0.1' will also return false
function IPToCardinal(P: PUTF8Char; out aValue: cardinal): boolean; overload;

/// convert an IPv4 'x.x.x.x' text into its 32-bit value
// - returns TRUE if the text was a valid IPv4 text, unserialized as 32-bit aValue
// - returns FALSE on parsing error, also setting aValue=0
// - '' or '127.0.0.1' will also return false
function IPToCardinal(const aIP: RawUTF8; out aValue: cardinal): boolean; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// convert an IPv4 'x.x.x.x' text into its 32-bit value, 0 or localhost
// - returns <> 0 value if the text was a valid IPv4 text, 0 on parsing error
// - '' or '127.0.0.1' will also return 0
function IPToCardinal(const aIP: RawUTF8): cardinal; overload;
  {$ifdef HASINLINE} inline;{$endif}

/// append a TGUID binary content as text
// - will store e.g. '3F2504E0-4F89-11D3-9A0C-0305E82C3301' (without any {})
// - this will be the format used for JSON encoding, e.g.
// $ { "UID": "C9A646D3-9C61-4CB7-BFCD-EE2522C8F633" }
function GUIDToText(P: PUTF8Char; guid: PByteArray): PUTF8Char;

/// convert a TGUID into UTF-8 encoded { text }
// - will return e.g. '{3F2504E0-4F89-11D3-9A0C-0305E82C3301}' (with the {})
// - if you do not need the embracing { }, use ToUTF8() overloaded function
function GUIDToRawUTF8(const guid: TGUID): RawUTF8;

/// convert a TGUID into UTF-8 encoded text
// - will return e.g. '3F2504E0-4F89-11D3-9A0C-0305E82C3301' (without the {})
// - if you need the embracing { }, use GUIDToRawUTF8() function instead
function ToUTF8(const guid: TGUID): RawUTF8; overload;

/// convert a TGUID into text
// - will return e.g. '{3F2504E0-4F89-11D3-9A0C-0305E82C3301}' (with the {})
// - this version is faster than the one supplied by SysUtils
function GUIDToString(const guid: TGUID): string;

type
  /// stack-allocated ASCII string, used by GUIDToShort() function
  TGUIDShortString = string[38];

/// convert a TGUID into text
// - will return e.g. '{3F2504E0-4F89-11D3-9A0C-0305E82C3301}' (with the {})
// - using a shortstring will allow fast allocation on the stack, so is
// preferred e.g. when providing a GUID to a ESynException.CreateUTF8()
function GUIDToShort(const
  guid: TGUID): TGUIDShortString; overload; {$ifdef HASINLINE} inline; {$endif}

/// convert a TGUID into text
// - will return e.g. '{3F2504E0-4F89-11D3-9A0C-0305E82C3301}' (with the {})
// - using a shortstring will allow fast allocation on the stack, so is
// preferred e.g. when providing a GUID to a ESynException.CreateUTF8()
procedure GUIDToShort(const
  guid: TGUID; out dest: TGUIDShortString); overload;

/// convert some text into its TGUID binary value
// - expect e.g. '3F2504E0-4F89-11D3-9A0C-0305E82C3301' (without any {})
// - return nil if the supplied text buffer is not a valid TGUID
// - this will be the format used for JSON encoding, e.g.
// $ { "UID": "C9A646D3-9C61-4CB7-BFCD-EE2522C8F633" }
function TextToGUID(P: PUTF8Char; guid: PByteArray): PUTF8Char;

/// read a TStream content into a String
// - it will read binary or text content from the current position until the
// end (using TStream.Size)
// - uses RawByteString for byte storage, whatever the codepage is
function StreamToRawByteString(aStream: TStream): RawByteString;

/// create a TStream from a string content
// - uses RawByteString for byte storage, whatever the codepage is
// - in fact, the returned TStream is a TRawByteString instance, since this
// function is just a wrapper around:
// ! result := TRawByteStringStream.Create(aString);
function RawByteStringToStream(const aString: RawByteString): TStream;
  {$ifdef HASINLINE}inline;{$endif}

/// read an UTF-8 text from a TStream
// - format is Length(Integer):Text, i.e. the one used by WriteStringToStream
// - will return '' if there is no such text in the stream
// - you can set a MaxAllowedSize value, if you know how long the size should be
// - it will read from the current position in S: so if you just write into S,
// it could be a good idea to rewind it before call, e.g.:
// !  WriteStringToStream(Stream,aUTF8Text);
// !  Stream.Seek(0,soBeginning);
// !  str := ReadStringFromStream(Stream);
function ReadStringFromStream(S: TStream;
  MaxAllowedSize: integer = 255): RawUTF8;

/// write an UTF-8 text into a TStream
// - format is Length(Integer):Text, i.e. the one used by ReadStringFromStream
function WriteStringToStream(S: TStream; const Text: RawUTF8): boolean;


implementation

uses
  mormot.core.datetime;

{$ifdef FPC}
  // globally disable some FPC paranoid warnings - rely on x86_64 as reference
  {$WARN 4056 off : Conversion between ordinals and pointers is not portable }
{$endif FPC}

 
{ ************ UTF-8 String Manipulation Functions }

function GetNextLine(source: PUTF8Char; out next: PUTF8Char; andtrim: boolean): RawUTF8;
var
  beg: PUTF8Char;
begin
  if source = nil then
  begin
    {$ifdef FPC}
    Finalize(result);
    {$else}
    result := '';
    {$endif}
    next := source;
    exit;
  end;
  if andtrim then // optional trim left
    while source^ in [#9, ' '] do
      inc(source);
  beg := source;
  repeat // just here to avoid a goto
    if source[0] > #13 then
      if source[1] > #13 then
        if source[2] > #13 then
          if source[3] > #13 then
          begin
            inc(source, 4); // fast process 4 chars per loop
            continue;
          end
          else
            inc(source, 3)
        else
          inc(source, 2)
      else
        inc(source);
    case source^ of
      #0:
        next := nil;
      #10:
        next := source + 1;
      #13:
        if source[1] = #10 then
          next := source + 2
        else
          next := source + 1;
    else
      begin
        inc(source);
        continue;
      end;
    end;
    if andtrim then // optional trim right
      while (source > beg) and (source[-1] in [#9, ' ']) do
        dec(source);
    FastSetString(result, beg, source - beg);
    exit;
  until false;
end;

function TrimLeft(const S: RawUTF8): RawUTF8;
var
  i, l: PtrInt;
begin
  l := Length(S);
  i := 1;
  while (i <= l) and (S[i] <= ' ') do
    Inc(i);
  Result := Copy(S, i, Maxint);
end;

function TrimRight(const S: RawUTF8): RawUTF8;
var
  i: PtrInt;
begin
  i := Length(S);
  while (i > 0) and (S[i] <= ' ') do
    Dec(i);
  FastSetString(result, pointer(S), i);
end;

procedure TrimCopy(const S: RawUTF8; start, count: PtrInt; out result: RawUTF8);
var
  L: PtrInt;
begin
  if count <= 0 then
    exit;
  if start <= 0 then
    start := 1;
  L := Length(S);
  while (start <= L) and (S[start] <= ' ') do
  begin
    inc(start);
    dec(count);
  end;
  dec(start);
  dec(L, start);
  if count < L then
    L := count;
  while L > 0 do
    if S[start + L] <= ' ' then
      dec(L)
    else
      break;
  if L > 0 then
    FastSetString(result, @PByteArray(S)[start], L);
end;

function SplitRight(const Str: RawUTF8; SepChar: AnsiChar; LeftStr: PRawUTF8): RawUTF8;
var
  i: PtrInt;
begin
  for i := length(Str) downto 1 do
    if Str[i] = SepChar then
    begin
      result := copy(Str, i + 1, maxInt);
      if LeftStr <> nil then
        LeftStr^ := copy(Str, 1, i - 1);
      exit;
    end;
  result := Str;
  if LeftStr <> nil then
    LeftStr^ := '';
end;

function SplitRights(const Str, SepChar: RawUTF8): RawUTF8;
var
  i, j, sep: PtrInt;
  c: AnsiChar;
begin
  sep := length(SepChar);
  if sep > 0 then
    if sep = 1 then
      result := SplitRight(Str, SepChar[1])
    else
    begin
      for i := length(Str) downto 1 do
      begin
        c := Str[i];
        for j := 1 to sep do
          if c = SepChar[j] then
          begin
            result := copy(Str, i + 1, maxInt);
            exit;
          end;
      end;
    end;
  result := Str;
end;

procedure Split(const Str, SepStr: RawUTF8; var LeftStr, RightStr: RawUTF8;
  ToUpperCase: boolean);
var
  i: integer;
  tmp: RawUTF8; // may be called as Split(Str,SepStr,Str,RightStr)
begin
  {$ifdef FPC} // to use fast FPC SSE version
  if length(SepStr) = 1 then
    i := PosExChar(SepStr[1], Str)
  else
  {$endif FPC}
    i := PosEx(SepStr, Str);
  if i = 0 then
  begin
    LeftStr := Str;
    RightStr := '';
  end
  else
  begin
    tmp := copy(Str, 1, i - 1);
    RightStr := copy(Str, i + length(SepStr), maxInt);
    LeftStr := tmp;
  end;
  if ToUpperCase then
  begin
    UpperCaseSelf(LeftStr);
    UpperCaseSelf(RightStr);
  end;
end;

function Split(const Str, SepStr: RawUTF8; var LeftStr: RawUTF8; ToUpperCase: boolean): RawUTF8;
begin
  Split(Str, SepStr, LeftStr, result, ToUpperCase);
end;

function Split(const Str: RawUTF8; const SepStr: array of RawUTF8;
  const DestPtr: array of PRawUTF8): PtrInt;
var
  s, i, j: PtrInt;
begin
  j := 1;
  result := 0;
  s := 0;
  if high(SepStr) >= 0 then
    while result <= high(DestPtr) do
    begin
      i := PosEx(SepStr[s], Str, j);
      if i = 0 then
      begin
        if DestPtr[result] <> nil then
          DestPtr[result]^ := copy(Str, j, MaxInt);
        inc(result);
        break;
      end;
      if DestPtr[result] <> nil then
        DestPtr[result]^ := copy(Str, j, i - j);
      inc(result);
      if s < high(SepStr) then
        inc(s);
      j := i + 1;
    end;
  for i := result to high(DestPtr) do
    if DestPtr[i] <> nil then
      DestPtr[i]^ := '';
end;

procedure FillZero(var secret: RawByteString);
begin
  if secret<>'' then
    with PStrRec(Pointer(PtrInt(secret) - _STRRECSIZE))^ do
      if refCnt=1 then // avoid GPF if const
        FillCharFast(pointer(secret)^, length, 0);
end;

procedure FillZero(var secret: RawUTF8);
begin
  FillZero(RawByteString(secret));
end;

procedure FillZero(var secret: SPIUTF8);
begin
  FillZero(RawByteString(secret));
end;

function StringReplaceAllProcess(const S, OldPattern, NewPattern: RawUTF8;
  found: integer): RawUTF8;
var
  oldlen, newlen, i, last, posCount, sharedlen: integer;
  pos: TIntegerDynArray;
  src, dst: PAnsiChar;
begin
  oldlen := length(OldPattern);
  newlen := length(NewPattern);
  SetLength(pos, 64);
  pos[0] := found;
  posCount := 1;
  repeat
    found := PosEx(OldPattern, S, found + oldlen);
    if found = 0 then
      break;
    AddInteger(pos, posCount, found);
  until false;
  FastSetString(result, nil, Length(S) + (newlen - oldlen) * posCount);
  last := 1;
  src := pointer(S);
  dst := pointer(result);
  for i := 0 to posCount - 1 do
  begin
    sharedlen := pos[i] - last;
    MoveFast(src^, dst^, sharedlen);
    inc(src, sharedlen + oldlen);
    inc(dst, sharedlen);
    if newlen > 0 then
    begin
      MoveSmall(pointer(NewPattern), dst, newlen);
      inc(dst, newlen);
    end;
    last := pos[i] + oldlen;
  end;
  MoveFast(src^, dst^, length(S) - last + 1);
end;

function StringReplaceAll(const S, OldPattern, NewPattern: RawUTF8): RawUTF8;
var
  found: integer;
begin
  if (S = '') or (OldPattern = '') or (OldPattern = NewPattern) then
    result := S
  else
  begin
    found := PosEx(OldPattern, S, 1); // our PosEx() is faster than Pos()
    if found = 0 then
      result := S
    else
      result := StringReplaceAllProcess(S, OldPattern, NewPattern, found);
  end;
end;

function StringReplaceAll(const S: RawUTF8;
  const OldNewPatternPairs: array of RawUTF8): RawUTF8;
var
  n, i: PtrInt;
begin
  result := S;
  n := high(OldNewPatternPairs);
  if (n > 0) and (n and 1 = 1) then
    for i := 0 to n shr 1 do
      result := StringReplaceAll(result,
        OldNewPatternPairs[i * 2], OldNewPatternPairs[i * 2 + 1]);
end;

function StringReplaceChars(const Source: RawUTF8; OldChar, NewChar: AnsiChar): RawUTF8;
var
  i, j, n: PtrInt;
begin
  if (OldChar <> NewChar) and (Source <> '') then
  begin
    n := length(Source);
    for i := 0 to n - 1 do
      if PAnsiChar(pointer(Source))[i] = OldChar then
      begin
        FastSetString(result, PAnsiChar(pointer(Source)), n);
        for j := i to n - 1 do
          if PAnsiChar(pointer(result))[j] = OldChar then
            PAnsiChar(pointer(result))[j] := NewChar;
        exit;
      end;
  end;
  result := Source;
end;

function StringReplaceTabs(const Source, TabText: RawUTF8): RawUTF8;

  procedure Process(S, D, T: PAnsiChar; TLen: integer);
  begin
    repeat
      if S^ = #0 then
        break
      else if S^ <> #9 then
      begin
        D^ := S^;
        inc(D);
        inc(S);
      end
      else
      begin
        if TLen > 0 then
        begin
          MoveSmall(T, D, TLen);
          inc(D, TLen);
        end;
        inc(S);
      end;
    until false;
  end;

var
  L, i, n, ttl: PtrInt;
begin
  ttl := length(TabText);
  L := Length(Source);
  n := 0;
  if ttl <> 0 then
    for i := 1 to L do
      if Source[i] = #9 then
        inc(n);
  if n = 0 then
  begin
    result := Source;
    exit;
  end;
  FastSetString(result, nil, L + n * pred(ttl));
  Process(pointer(Source), pointer(result), pointer(TabText), ttl);
end;

function QuotedStr(const S: RawUTF8; Quote: AnsiChar): RawUTF8;
begin
  QuotedStr(S, Quote, result);
end;

procedure QuotedStr(const S: RawUTF8; Quote: AnsiChar; var result: RawUTF8);
var
  i, L, quote1, nquote: PtrInt;
  P, R: PUTF8Char;
  tmp: pointer; // will hold a RawUTF8 with no try..finally exception block
  c: AnsiChar;
begin
  tmp := nil;
  L := length(S);
  P := pointer(S);
  if (P <> nil) and (P = pointer(result)) then
  begin
    RawUTF8(tmp) := S; // make private ref-counted copy for QuotedStr(U,'"',U)
    P := pointer(tmp);
  end;
  nquote := 0;
  {$ifdef FPC} // will use fast FPC SSE version
  quote1 := IndexByte(P^, L, byte(Quote));
  if quote1 >= 0 then
    for i := quote1 to L - 1 do
      if P[i] = Quote then
        inc(nquote);
  {$else}
  quote1 := 0;
  for i := 0 to L - 1 do
    if P[i] = Quote then
    begin
      if nquote = 0 then
        quote1 := i;
      inc(nquote);
    end;
  {$endif FPC}
  FastSetString(result, nil, L + nquote + 2);
  R := pointer(result);
  R^ := Quote;
  inc(R);
  if nquote = 0 then
  begin
    MoveFast(P^, R^, L);
    R[L] := Quote;
  end
  else
  begin
    MoveFast(P^, R^, quote1);
    inc(R, quote1);
    inc(quote1, PtrInt(P)); // trick for reusing a register on FPC
    repeat
      c := PAnsiChar(quote1)^;
      if c = #0 then
        break;
      inc(quote1);
      R^ := c;
      inc(R);
      if c <> Quote then
        continue;
      R^ := c;
      inc(R);
    until false;
    R^ := Quote;
  end;
  if tmp <> nil then
    {$ifdef FPC}
    Finalize(RawUTF8(tmp));
    {$else}
    RawUTF8(tmp) := '';
    {$endif}
end;

function GotoEndOfQuotedString(P: PUTF8Char): PUTF8Char;
var
  quote: AnsiChar;
begin // P^=" or P^=' at function call
  quote := P^;
  inc(P);
  repeat
    if P^ = #0 then
      break
    else if P^ <> quote then
      inc(P)
    else if P[1] = quote then // allow double quotes inside string
      inc(P, 2)
    else
      break; // end quote
  until false;
  result := P;
end; // P^='"' at function return

function GotoNextNotSpace(P: PUTF8Char): PUTF8Char;
begin
  {$ifdef FPC}
  while (P^ <= ' ') and (P^ <> #0) do
    inc(P);
  {$else}
  if P^ in [#1..' '] then
    repeat
      inc(P)
    until not (P^ in [#1..' ']);
  {$endif FPC}
  result := P;
end;

function GotoNextNotSpaceSameLine(P: PUTF8Char): PUTF8Char;
begin
  while P^ in [#9, ' '] do
    inc(P);
  result := P;
end;

function GotoNextSpace(P: PUTF8Char): PUTF8Char;
begin
  if P^ > ' ' then
    repeat
      inc(P)
    until P^ <= ' ';
  result := P;
end;

function NextNotSpaceCharIs(var P: PUTF8Char; ch: AnsiChar): boolean;
begin
  while (P^ <= ' ') and (P^ <> #0) do
    inc(P);
  if P^ = ch then
  begin
    inc(P);
    result := true;
  end
  else
    result := false;
end;

function GetNextFieldProp(var P: PUTF8Char; var Prop: RawUTF8): boolean;
var
  B: PUTF8Char;
  tab: PTextCharSet;
begin
  tab := @TEXT_CHARS;
  while tcCtrlNot0Comma in tab[P^] do
    inc(P); // in [#1..' ', ';']
  B := P;
  while tcIdentifier in tab[P^] do
    inc(P); // go to end of ['_', '0'..'9', 'a'..'z', 'A'..'Z'] chars
  FastSetString(Prop, B, P - B);
  while tcCtrlNot0Comma in tab[P^] do
    inc(P);
  result := Prop <> '';
end;

function GetNextFieldPropSameLine(var P: PUTF8Char; var Prop: ShortString): boolean;
var
  B: PUTF8Char;
  tab: PTextCharSet;
begin
  tab := @TEXT_CHARS;
  while tcCtrlNotLF in tab[P^] do
    inc(P); // ignore [#1..#9, #11, #12, #14..' ']
  B := P;
  while tcIdentifier in tab[P^] do
    inc(P); // go to end of field name
  SetString(Prop, PAnsiChar(B), P - B);
  while tcCtrlNotLF in TEXT_CHARS[P^] do
    inc(P);
  result := Prop <> '';
end;

function UnQuoteSQLStringVar(P: PUTF8Char; out Value: RawUTF8): PUTF8Char;
var
  quote: AnsiChar;
  PBeg, PS: PUTF8Char;
  internalquote: PtrInt;
begin
  if P = nil then
  begin
    result := nil;
    exit;
  end;
  quote := P^; // " or '
  inc(P);
  // compute unquoted string length
  PBeg := P;
  internalquote := 0;
  repeat
    if P^ = #0 then
      break;
    if P^ <> quote then
      inc(P)
    else if P[1] = quote then
    begin
      inc(P, 2); // allow double quotes inside string
      inc(internalquote);
    end
    else
      break; // end quote
  until false;
  if P^ = #0 then
  begin
    result := nil; // end of string before end quote -> incorrect
    exit;
  end;
  // create unquoted string
  if internalquote = 0 then
    // no quote within
    FastSetString(Value, PBeg, P - PBeg)
  else
  begin
    // unescape internal quotes
    SetLength(Value, P - PBeg - internalquote);
    P := PBeg;
    PS := Pointer(Value);
    repeat
      if P^ = quote then
        if P[1] = quote then
          inc(P)
        else // allow double quotes inside string
          break; // end quote
      PS^ := P^;
      inc(PByte(PS));
      inc(P);
    until false;
  end;
  result := P + 1;
end;

function UnQuoteSQLString(const Value: RawUTF8): RawUTF8;
begin
  UnQuoteSQLStringVar(pointer(Value), result);
end;

function UnQuotedSQLSymbolName(const ExternalDBSymbol: RawUTF8): RawUTF8;
begin
  if (ExternalDBSymbol <> '') and
     (ExternalDBSymbol[1] in ['[', '"', '''', '(']) then // e.g. for ZDBC's GetFields()
    result := copy(ExternalDBSymbol, 2, length(ExternalDBSymbol) - 2)
  else
    result := ExternalDBSymbol;
end;

function IdemPCharAndGetNextLine(var source: PUTF8Char; searchUp: PAnsiChar): boolean;
begin
  if source = nil then
    result := false
  else
  begin
    result := IdemPChar(source, searchUp);
    source := GotoNextLine(source);
  end;
end;

function FindNameValue(P: PUTF8Char; UpperName: PAnsiChar): PUTF8Char;
var
  {$ifdef CPUX86NOTPIC}
  table: TNormTable absolute NormToUpperAnsi7;
  {$else}
  table: PNormTable;
  {$endif}
  c: AnsiChar;
  u: PAnsiChar;
label
  _0;
begin
  if (P = nil) or (UpperName = nil) then
    goto _0;
  {$ifndef CPUX86NOTPIC} table := @NormToUpperAnsi7; {$endif}
  repeat
    c := UpperName^;
    if table[P^] = c then // first character is likely not to match
    begin
      inc(P);
      u := UpperName + 1;
      repeat
        c := u^;
        inc(u);
        if c <> #0 then
        begin
          if table[P^] <> c then
            break;
          inc(P);
          continue;
        end;
        result := P; // if found, points just after UpperName
        exit;
      until false;
    end;
    repeat // quickly go to end of current line
      repeat
        c := P^;
        inc(P);
      until c <= #13;
      if c = #13 then // most common case is text ending with #13#10
        repeat
          c := P^;
          if (c <> #10) and (c <> #13) then
            break;
          inc(P);
        until false
      else if c <> #10 then
        if c <> #0 then
          continue // e.g. #9
        else
          goto _0
      else
        repeat
          c := P^;
          if c <> #10 then
            break;
          inc(P);
        until false;
      if c <> #0 then
        break; // check if UpperName is at the begining of the new line
_0:   result := nil; // reached P^=#0 -> not found
      exit;
    until false;
  until false;
end;

function FindNameValue(const NameValuePairs: RawUTF8; UpperName: PAnsiChar;
  var Value: RawUTF8): boolean;
var
  P: PUTF8Char;
  L: PtrInt;
begin
  P := FindNameValue(pointer(NameValuePairs), UpperName);
  if P <> nil then
  begin
    while P^ in [#9, ' '] do // trim left
      inc(P);
    L := 0;
    while P[L] > #13 do // end of line/value
      inc(L);
    while P[L - 1] = ' ' do // trim right
      dec(L);
    FastSetString(Value, P, L);
    result := true;
  end
  else
  begin
    {$ifdef FPC} Finalize(Value); {$else} Value := ''; {$endif}
    result := false;
  end;
end;

function GetLineSize(P, PEnd: PUTF8Char): PtrUInt;
var
  c: byte;
begin
  {$ifdef CPUX64}
  if PEnd <> nil then
  begin
    result := BufferLineLength(P, PEnd); // use branchless SSE2 on x86_64
    exit;
  end;
  result := PtrUInt(P) - 1;
  {$else}
  result := PtrUInt(P) - 1;
  if PEnd <> nil then
    repeat // inlined BufferLineLength()
      inc(result);
      if PtrUInt(result) < PtrUInt(PEnd) then
      begin
        c := PByte(result)^;
        if (c > 13) or ((c <> 10) and (c <> 13)) then
          continue;
      end;
      break;
    until false
  else
  {$endif CPUX64}
    repeat // inlined BufferLineLength() ending at #0 for PEnd=nil
      inc(result);
      c := PByte(result)^;
      if (c > 13) or ((c <> 0) and (c <> 10) and (c <> 13)) then
        continue;
      break;
    until false;
  dec(result, PtrUInt(P)); // returns length
end;

function GetLineSizeSmallerThan(P, PEnd: PUTF8Char; aMinimalCount: integer): boolean;
begin
  result := false;
  if P <> nil then
    while (P < PEnd) and (P^ <> #10) and (P^ <> #13) do
      if aMinimalCount = 0 then
        exit
      else
      begin
        dec(aMinimalCount);
        inc(P);
      end;
  result := true;
end;

function GetNextStringLineToRawUnicode(var P: PChar): RawUnicode;
var
  S: PChar;
begin
  if P = nil then
    result := ''
  else
  begin
    S := P;
    while S^ >= ' ' do
      inc(S);
    result := StringToRawUnicode(P, S - P);
    while (S^ <> #0) and (S^ < ' ') do
      inc(S); // ignore e.g. #13 or #10
    if S^ <> #0 then
      P := S
    else
      P := nil;
  end;
end;

function TrimLeftLowerCase(const V: RawUTF8): PUTF8Char;
begin
  result := Pointer(V);
  if result <> nil then
  begin
    while result^ in ['a'..'z'] do
      inc(result);
    if result^ = #0 then
      result := Pointer(V);
  end;
end;

function TrimLeftLowerCaseToShort(V: PShortString): ShortString;
begin
  TrimLeftLowerCaseToShort(V, result);
end;

procedure TrimLeftLowerCaseToShort(V: PShortString; out result: ShortString);
var
  P: PAnsiChar;
  L: integer;
begin
  L := length(V^);
  P := @V^[1];
  while (L > 0) and (P^ in ['a'..'z']) do
  begin
    inc(P);
    dec(L);
  end;
  if L = 0 then
    result := V^
  else
    SetString(result, P, L);
end;

function TrimLeftLowerCaseShort(V: PShortString): RawUTF8;
var
  P: PAnsiChar;
  L: integer;
begin
  L := length(V^);
  P := @V^[1];
  while (L > 0) and (P^ in ['a'..'z']) do
  begin
    inc(P);
    dec(L);
  end;
  if L = 0 then
    FastSetString(result, @V^[1], length(V^))
  else
    FastSetString(result, P, L);
end;

procedure AppendShortComma(text: PAnsiChar; len: PtrInt; var result: shortstring;
  trimlowercase: boolean);
begin
  if trimlowercase then
    while text^ in ['a'..'z'] do
      if len = 1 then
        exit
      else
      begin
        inc(text);
        dec(len);
      end;
  if integer(ord(result[0])) + len >= 255 then
    exit;
  if len > 0 then
    MoveSmall(text, @result[ord(result[0]) + 1], len);
  inc(result[0], len + 1);
  result[ord(result[0])] := ',';
end;

function IdemPropNameUSmallNotVoid(P1, P2, P1P2Len: PtrInt): boolean;
  {$ifdef HASINLINE} inline;{$endif}
label
  zero;
begin
  inc(P1P2Len, P1);
  dec(P2, P1);
  repeat
    if (PByte(P1)^ xor ord(PAnsiChar(P1)[P2])) and $df <> 0 then
      goto zero;
    inc(P1);
  until P1 >= P1P2Len;
  result := true;
  exit;
zero:
  result := false;
end;

function FindShortStringListExact(List: PShortString; MaxValue: integer;
  aValue: PUTF8Char; aValueLen: PtrInt): integer;
var
  PLen: PtrInt;
begin
  if aValueLen <> 0 then
    for result := 0 to MaxValue do
    begin
      PLen := PByte(List)^;
      if (PLen = aValueLen) and
         IdemPropNameUSmallNotVoid(PtrInt(@List^[1]), PtrInt(aValue), PLen) then
        exit;
      List := pointer(@PAnsiChar(PLen)[PtrUInt(List) + 1]); // next
    end;
  result := -1;
end;

function FindShortStringListTrimLowerCase(List: PShortString; MaxValue: integer;
  aValue: PUTF8Char; aValueLen: PtrInt): integer;
var
  PLen: PtrInt;
begin
  if aValueLen <> 0 then
    for result := 0 to MaxValue do
    begin
      PLen := ord(List^[0]);
      inc(PUTF8Char(List));
      repeat // trim lower case
        if not (PUTF8Char(List)^ in ['a'..'z']) then
          break;
        inc(PUTF8Char(List));
        dec(PLen);
      until PLen = 0;
      if (PLen = aValueLen) and
         IdemPropNameUSmallNotVoid(PtrInt(aValue), PtrInt(List), PLen) then
        exit;
      inc(PUTF8Char(List), PLen); // next
    end;
  result := -1;
end;

function FindShortStringListTrimLowerCaseExact(List: PShortString; MaxValue: integer;
  aValue: PUTF8Char; aValueLen: PtrInt): integer;
var
  PLen: PtrInt;
begin
  if aValueLen <> 0 then
    for result := 0 to MaxValue do
    begin
      PLen := ord(List^[0]);
      inc(PUTF8Char(List));
      repeat
        if not (PUTF8Char(List)^ in ['a'..'z']) then
          break;
        inc(PUTF8Char(List));
        dec(PLen);
      until PLen = 0;
      if (PLen = aValueLen) and CompareMemFixed(aValue, List, PLen) then
        exit;
      inc(PUTF8Char(List), PLen);
    end;
  result := -1;
end;

function UnCamelCase(const S: RawUTF8): RawUTF8;
var
  tmp: TSynTempBuffer;
  destlen: PtrInt;
begin
  if S = '' then
    result := ''
  else
  begin
    destlen := UnCamelCase(tmp.Init(length(S) * 2), pointer(S));
    tmp.Done(PAnsiChar(tmp.buf) + destlen, result);
  end;
end;

function UnCamelCase(D, P: PUTF8Char): integer;
var
  Space, SpaceBeg, DBeg: PUTF8Char;
  CapitalCount: integer;
  Number: boolean;
label
  Next;
begin
  DBeg := D;
  if (D <> nil) and (P <> nil) then
  begin // avoid GPF
    Space := D;
    SpaceBeg := D;
    repeat
      CapitalCount := 0;
      Number := P^ in ['0'..'9'];
      if Number then
        repeat
          inc(CapitalCount);
          D^ := P^;
          inc(P);
          inc(D);
        until not (P^ in ['0'..'9'])
      else
        repeat
          inc(CapitalCount);
          D^ := P^;
          inc(P);
          inc(D);
        until not (P^ in ['A'..'Z']);
      if P^ = #0 then
        break; // no lowercase conversion of last fully uppercased word
      if (CapitalCount > 1) and not Number then
      begin
        dec(P);
        dec(D);
      end;
      while P^ in ['a'..'z'] do
      begin
        D^ := P^;
        inc(D);
        inc(P);
      end;
      if P^ = '_' then
        if P[1] = '_' then
        begin
          D^ := ':';
          inc(P);
          inc(D);
          goto Next;
        end
        else
        begin
          PWord(D)^ := ord(' ') + ord('-') shl 8;
          inc(D, 2);
Next:     if Space = SpaceBeg then
            SpaceBeg := D + 1;
          inc(P);
          Space := D + 1;
        end
      else
        Space := D;
      if P^ = #0 then
        break;
      D^ := ' ';
      inc(D);
    until false;
    if Space > DBeg then
      dec(Space);
    while Space > SpaceBeg do
    begin
      if Space^ in ['A'..'Z'] then
        if not (Space[1] in ['A'..'Z', ' ']) then
          inc(Space^, 32); // lowercase conversion of not last fully uppercased word
      dec(Space);
    end;
  end;
  result := D - DBeg;
end;

procedure CamelCase(P: PAnsiChar; len: PtrInt; var s: RawUTF8; const isWord: TSynByteSet);
var
  i: PtrInt;
  d: PAnsiChar;
  tmp: array[byte] of AnsiChar;
begin
  if len > SizeOf(tmp) then
    len := SizeOf(tmp);
  for i := 0 to len - 1 do
    if not (ord(P[i]) in isWord) then
    begin
      if i > 0 then
      begin
        MoveSmall(P, @tmp, i);
        inc(P, i);
        dec(len, i);
      end;
      d := @tmp[i];
      while len > 0 do
      begin
        while (len > 0) and not (ord(P^) in isWord) do
        begin
          inc(P);
          dec(len);
        end;
        if len = 0 then
          break;
        d^ := NormToUpperAnsi7[P^];
        inc(d);
        repeat
          inc(P);
          dec(len);
          if not (ord(P^) in isWord) then
            break;
          d^ := P^;
          inc(d);
        until len = 0;
      end;
      P := @tmp;
      len := d - tmp;
      break;
    end;
  FastSetString(s, P, len);
end;

procedure CamelCase(const text: RawUTF8; var s: RawUTF8; const isWord: TSynByteSet);
begin
  CamelCase(pointer(text), length(text), s, isWord);
end;

procedure GetCaptionFromPCharLen(P: PUTF8Char; out result: string);
var
  Temp: array[byte] of AnsiChar;
begin
  if P = nil then
    exit;
  {$ifdef UNICODE}
  UTF8DecodeToUnicodeString(Temp, UnCamelCase(@Temp, P), result);
  {$else}
  SetString(result, PAnsiChar(@Temp), UnCamelCase(@Temp, P));
  {$endif UNICODE}
  if Assigned(LoadResStringTranslate) then
    LoadResStringTranslate(result);
end;


{ ************ CSV-like Iterations over Text Buffers }

function IdemPCharAndGetNextItem(var source: PUTF8Char; const searchUp: RawUTF8;
  var Item: RawUTF8; Sep: AnsiChar): boolean;
begin
  if source <> nil then
    if IdemPChar(source, Pointer(searchUp)) then
    begin
      inc(source, Length(searchUp));
      GetNextItem(source, Sep, Item);
      result := true;
      exit;
    end;
  result := false;
end;

function GetNextItem(var P: PUTF8Char; Sep: AnsiChar): RawUTF8;
begin
  GetNextItem(P, Sep, result);
end;

procedure GetNextItem(var P: PUTF8Char; Sep: AnsiChar; var result: RawUTF8);
var
  S: PUTF8Char;
begin
  if P = nil then
    result := ''
  else
  begin
    S := P;
    while (S^ <> #0) and (S^ <> Sep) do
      inc(S);
    FastSetString(result, P, S - P);
    if S^ <> #0 then
      P := S + 1
    else
      P := nil;
  end;
end;

procedure GetNextItem(var P: PUTF8Char; Sep, Quote: AnsiChar; var result: RawUTF8);
begin
  if P = nil then
    result := ''
  else if P^ = Quote then
  begin
    P := UnQuoteSQLStringVar(P, result);
    if P = nil then
      result := ''
    else if P^ <> #0 then
      inc(P);
  end
  else
    GetNextItem(P, Sep, result);
end;

procedure GetNextItemTrimed(var P: PUTF8Char; Sep: AnsiChar; var result: RawUTF8);
var
  S, E: PUTF8Char;
begin
  if (P = nil) or (Sep <= ' ') then
    result := ''
  else
  begin
    while (P^ <= ' ') and (P^ <> #0) do
      inc(P); // trim left
    S := P;
    while (S^ <> #0) and (S^ <> Sep) do
      inc(S);
    E := S;
    while (E > P) and (E[-1] in [#1..' ']) do
      dec(E); // trim right
    FastSetString(result, P, E - P);
    if S^ <> #0 then
      P := S + 1
    else
      P := nil;
  end;
end;

procedure GetNextItemTrimedCRLF(var P: PUTF8Char; var result: RawUTF8);
var
  S, E: PUTF8Char;
begin
  if P = nil then
    result := ''
  else
  begin
    S := P;
    while (S^ <> #0) and (S^ <> #10) do
      inc(S);
    E := S;
    if (E > P) and (E[-1] = #13) then
      dec(E);
    FastSetString(result, P, E - P);
    if S^ <> #0 then
      P := S + 1
    else
      P := nil;
  end;
end;

function GetNextItemString(var P: PChar; Sep: Char): string;
var
  S: PChar;
begin
  if P = nil then
    result := ''
  else
  begin
    S := P;
    while (S^ <> #0) and (S^ <> Sep) do
      inc(S);
    SetString(result, P, S - P);
    if S^ <> #0 then
      P := S + 1
    else
      P := nil;
  end;
end;

function GetFileNameExtIndex(const FileName, CSVExt: TFileName): integer;
var
  Ext: TFileName;
  P: PChar;
begin
  result := -1;
  P := pointer(CSVExt);
  Ext := ExtractFileExt(FileName);
  if (P = nil) or (Ext = '') or (Ext[1] <> '.') then
    exit;
  delete(Ext, 1, 1);
  repeat
    inc(result);
    if SameText(GetNextItemString(P), Ext) then
      exit;
  until P = nil;
  result := -1;
end;

procedure AppendCSVValues(const CSV: string; const Values: array of string;
  var Result: string; const AppendBefore: string);
var
  s: string;
  i, bool: integer;
  P: PChar;
  first: Boolean;
begin
  P := pointer(CSV);
  if P = nil then
    exit;
  first := True;
  for i := 0 to high(Values) do
  begin
    s := GetNextItemString(P);
    if Values[i] <> '' then
    begin
      if first then
      begin
        Result := Result + #13#10;
        first := false;
      end
      else
        Result := Result + AppendBefore;
      bool := FindCSVIndex('0,-1', RawUTF8(Values[i]));
      Result := Result + s + ': ';
      if bool < 0 then
        Result := Result + Values[i]
      else
        Result := Result + GetCSVItemString(pointer(GetNextItemString(P)), bool, '/');
    end;
  end;
end;

procedure GetNextItemShortString(var P: PUTF8Char; out Dest: ShortString; Sep: AnsiChar);
var
  S: PUTF8Char;
  len: PtrInt;
begin
  S := P;
  if S <> nil then
  begin
    while (S^ <= ' ') and (S^ <> #0) do
      inc(S);
    P := S;
    if (S^ <> #0) and (S^ <> Sep) then
      repeat
        inc(S);
      until (S^ = #0) or (S^ = Sep);
    len := S - P;
    repeat
      dec(len);
    until (len < 0) or not (P[len] in [#1..' ']); // trim right spaces
    if len >= 255 then
      len := 255
    else
      inc(len);
    Dest[0] := AnsiChar(len);
    MoveSmall(P, @Dest[1], len);
    if S^ <> #0 then
      P := S + 1
    else
      P := nil;
  end
  else
    Dest[0] := #0;
end;

function GetNextItemHexDisplayToBin(var P: PUTF8Char;
  Bin: PByte; BinBytes: integer; Sep: AnsiChar): boolean;
var
  S: PUTF8Char;
  len: integer;
begin
  result := false;
  FillCharFast(Bin^, BinBytes, 0);
  if P = nil then
    exit;
  while (P^ <= ' ') and (P^ <> #0) do
    inc(P);
  S := P;
  if Sep = #0 then
    while S^ > ' ' do
      inc(S)
  else
    while (S^ <> #0) and (S^ <> Sep) do
      inc(S);
  len := S - P;
  while (P[len - 1] in [#1..' ']) and (len > 0) do
    dec(len); // trim right spaces
  if len <> BinBytes * 2 then
    exit;
  if not HexDisplayToBin(PAnsiChar(P), Bin, BinBytes) then
    FillCharFast(Bin^, BinBytes, 0)
  else
  begin
    if S^ = #0 then
      P := nil
    else if Sep <> #0 then
      P := S + 1
    else
      P := S;
    result := true;
  end;
end;

function GetNextItemCardinal(var P: PUTF8Char; Sep: AnsiChar): PtrUInt;
var
  c: PtrUInt;
begin
  if P = nil then
  begin
    result := 0;
    exit;
  end;
  if P^ = ' ' then
    repeat
      inc(P)
    until P^ <> ' ';
  c := byte(P^) - 48;
  if c > 9 then
    result := 0
  else
  begin
    result := c;
    inc(P);
    repeat
      c := byte(P^) - 48;
      if c > 9 then
        break
      else
        result := result * 10 + c;
      inc(P);
    until false;
  end;
  if Sep <> #0 then
    while (P^ <> #0) and (P^ <> Sep) do // go to end of CSV item (ignore any decimal)
      inc(P);
  if P^ = #0 then
    P := nil
  else if Sep <> #0 then
    inc(P);
end;

function GetNextItemCardinalStrict(var P: PUTF8Char): PtrUInt;
var
  c: PtrUInt;
begin
  if P = nil then
  begin
    result := 0;
    exit;
  end;
  c := byte(P^) - 48;
  if c > 9 then
    result := 0
  else
  begin
    result := c;
    inc(P);
    repeat
      c := byte(P^) - 48;
      if c > 9 then
        break
      else
        result := result * 10 + c;
      inc(P);
    until false;
  end;
  if P^ = #0 then
    P := nil;
end;

function CSVOfValue(const Value: RawUTF8; Count: cardinal; const Sep: RawUTF8): RawUTF8;
var
  ValueLen, SepLen: cardinal;
  i: cardinal;
  P: PAnsiChar;
begin // CSVOfValue('?',3)='?,?,?'
  result := '';
  if Count = 0 then
    exit;
  ValueLen := length(Value);
  SepLen := Length(Sep);
  FastSetString(result, nil, ValueLen * Count + SepLen * pred(Count));
  P := pointer(result);
  i := 1;
  repeat
    if ValueLen > 0 then
    begin
      MoveSmall(Pointer(Value), P, ValueLen);
      inc(P, ValueLen);
    end;
    if i = Count then
      break;
    if SepLen > 0 then
    begin
      MoveSmall(Pointer(Sep), P, SepLen);
      inc(P, SepLen);
    end;
    inc(i);
  until false;
  // assert(P-pointer(result)=length(result));
end;

procedure SetBitCSV(var Bits; BitsCount: integer; var P: PUTF8Char);
var
  bit, last: cardinal;
begin
  while P <> nil do
  begin
    bit := GetNextItemCardinalStrict(P) - 1; // '0' marks end of list
    if bit >= cardinal(BitsCount) then
      break; // avoid GPF
    if (P = nil) or (P^ = ',') then
      SetBitPtr(@Bits, bit)
    else if P^ = '-' then
    begin
      inc(P);
      last := GetNextItemCardinalStrict(P) - 1; // '0' marks end of list
      if last >= Cardinal(BitsCount) then
        exit;
      while bit <= last do
      begin
        SetBitPtr(@Bits, bit);
        inc(bit);
      end;
    end;
    if (P <> nil) and (P^ = ',') then
      inc(P);
  end;
  if (P <> nil) and (P^ = ',') then
    inc(P);
end;

function GetBitCSV(const Bits; BitsCount: integer): RawUTF8;
var
  i, j: integer;
begin
  result := '';
  i := 0;
  while i < BitsCount do
    if GetBitPtr(@Bits, i) then
    begin
      j := i;
      while (j + 1 < BitsCount) and GetBitPtr(@Bits, j + 1) do
        inc(j);
      result := result + UInt32ToUtf8(i + 1);
      if j = i then
        result := result + ','
      else if j = i + 1 then
        result := result + ',' + UInt32ToUtf8(j + 1) + ','
      else
        result := result + '-' + UInt32ToUtf8(j + 1) + ',';
      i := j + 1;
    end
    else
      inc(i);
  result := result + '0'; // '0' marks end of list
end;

function GetNextItemCardinalW(var P: PWideChar; Sep: WideChar = ','): PtrUInt;
var
  c: PtrUInt;
begin
  if P = nil then
  begin
    result := 0;
    exit;
  end;
  c := word(P^) - 48;
  if c > 9 then
    result := 0
  else
  begin
    result := c;
    inc(P);
    repeat
      c := word(P^) - 48;
      if c > 9 then
        break
      else
        result := result * 10 + c;
      inc(P);
    until false;
  end;
  while (P^ <> #0) and (P^ <> Sep) do // go to end of CSV item (ignore any decimal)
    inc(P);
  if P^ = #0 then
    P := nil
  else
    inc(P);
end;

function GetNextItemInteger(var P: PUTF8Char; Sep: AnsiChar): PtrInt;
var
  minus: boolean;
begin
  if P = nil then
  begin
    result := 0;
    exit;
  end;
  if P^ = ' ' then
    repeat
      inc(P)
    until P^ <> ' ';
  if (P^ in ['+', '-']) then
  begin
    minus := P^ = '-';
    inc(P);
  end
  else
    minus := false;
  result := PtrInt(GetNextItemCardinal(P, Sep));
  if minus then
    result := -result;
end;

function GetNextTChar64(var P: PUTF8Char; Sep: AnsiChar; out Buf: TChar64): PtrInt;
var
  S: PUTF8Char;
  c: AnsiChar;
begin
  result := 0;
  S := P;
  if S = nil then
    exit;
  if Sep = #0 then
    repeat // store up to next whitespace
      c := S[result];
      if c <= ' ' then
        break;
      Buf[result] := c;
      inc(result);
      if result >= SizeOf(Buf) then
        exit; // avoid buffer overflow
    until false
  else
    repeat // store up to Sep or end of string
      c := S[result];
      if (c = #0) or (c = Sep) then
        break;
      Buf[result] := c;
      inc(result);
      if result >= SizeOf(Buf) then
        exit; // avoid buffer overflow
    until false;
  Buf[result] := #0; // make asciiz
  inc(S, result); // S[result]=Sep or #0
  if S^ = #0 then
    P := nil
  else if Sep = #0 then
    P := S
  else
    P := S + 1;
end;

{$ifdef CPU64}

function GetNextItemInt64(var P: PUTF8Char; Sep: AnsiChar): Int64;
begin
  result := GetNextItemInteger(P, Sep); // PtrInt=Int64
end;

function GetNextItemQWord(var P: PUTF8Char; Sep: AnsiChar): QWord;
begin
  result := GetNextItemCardinal(P, Sep); // PtrUInt=QWord
end;

{$else}

function GetNextItemInt64(var P: PUTF8Char; Sep: AnsiChar): Int64;
var
  tmp: TChar64;
begin
  if GetNextTChar64(P, Sep, tmp) > 0 then
    SetInt64(tmp, result)
  else
    result := 0;
end;

function GetNextItemQWord(var P: PUTF8Char; Sep: AnsiChar): QWord;
var
  tmp: TChar64;
begin
  if GetNextTChar64(P, Sep, tmp) > 0 then
    SetQWord(tmp, result)
  else
    result := 0;
end;

{$endif CPU64}

function GetNextItemHexa(var P: PUTF8Char; Sep: AnsiChar): QWord;
var
  tmp: TChar64;
  L: integer;
begin
  result := 0;
  L := GetNextTChar64(P, Sep, tmp);
  if (L > 0) and (L and 1 = 0) then
    if not HexDisplayToBin(@tmp, @result, L shr 1) then
      result := 0;
end;

function GetNextItemDouble(var P: PUTF8Char; Sep: AnsiChar): double;
var
  tmp: TChar64;
  err: integer;
begin
  if GetNextTChar64(P, Sep, tmp) > 0 then
  begin
    result := GetExtended(tmp, err);
    if err <> 0 then
      result := 0;
  end
  else
    result := 0;
end;

function GetNextItemCurrency(var P: PUTF8Char; Sep: AnsiChar): TSynCurrency;
begin
  GetNextItemCurrency(P, result, Sep);
end;

procedure GetNextItemCurrency(var P: PUTF8Char; out result: TSynCurrency; Sep: AnsiChar);
var
  tmp: TChar64;
begin
  if GetNextTChar64(P, Sep, tmp) > 0 then
    PInt64(@result)^ := StrToCurr64(tmp)
  else
    result := 0;
end;

function GetCSVItem(P: PUTF8Char; Index: PtrUInt; Sep: AnsiChar): RawUTF8;
var
  i: PtrUInt;
begin
  if P = nil then
    result := ''
  else
    for i := 0 to Index do
      GetNextItem(P, Sep, result);
end;

function GetUnQuoteCSVItem(P: PUTF8Char; Index: PtrUInt; Sep, Quote: AnsiChar): RawUTF8;
var
  i: PtrUInt;
begin
  if P = nil then
    result := ''
  else
    for i := 0 to Index do
      GetNextItem(P, Sep, Quote, result);
end;

function GetLastCSVItem(const CSV: RawUTF8; Sep: AnsiChar): RawUTF8;
var
  i: integer;
begin
  for i := length(CSV) downto 1 do
    if CSV[i] = Sep then
    begin
      result := copy(CSV, i + 1, maxInt);
      exit;
    end;
  result := CSV;
end;

function GetCSVItemString(P: PChar; Index: PtrUInt; Sep: Char): string;
var
  i: PtrUInt;
begin
  if P = nil then
    result := ''
  else
    for i := 0 to Index do
      result := GetNextItemString(P, Sep);
end;

function FindCSVIndex(CSV: PUTF8Char; const Value: RawUTF8; Sep: AnsiChar;
  CaseSensitive, TrimValue: boolean): integer;
var
  s: RawUTF8;
begin
  result := 0;
  while CSV <> nil do
  begin
    GetNextItem(CSV, Sep, s);
    if TrimValue then
      s := trim(s);
    if CaseSensitive then
    begin
      if s = Value then
        exit;
    end
    else if SameTextU(s, Value) then
      exit;
    inc(result);
  end;
  result := -1; // not found
end;

procedure CSVToRawUTF8DynArray(CSV: PUTF8Char; var Result: TRawUTF8DynArray;
  Sep: AnsiChar; TrimItems, AddVoidItems: boolean);
var
  s: RawUTF8;
  n: integer;
begin
  n := length(Result);
  while CSV <> nil do
  begin
    if TrimItems then
      GetNextItemTrimed(CSV, Sep, s)
    else
      GetNextItem(CSV, Sep, s);
    if (s <> '') or AddVoidItems then
      AddRawUTF8(Result, n, s);
  end;
  if n <> length(Result) then
    SetLength(Result, n);
end;

procedure CSVToRawUTF8DynArray(const CSV, Sep, SepEnd: RawUTF8; var Result: TRawUTF8DynArray);
var
  offs, i: integer;
begin
  offs := 1;
  while offs < length(CSV) do
  begin
    SetLength(Result, length(Result) + 1);
    i := PosEx(Sep, CSV, offs);
    if i = 0 then
    begin
      i := PosEx(SepEnd, CSV, offs);
      if i = 0 then
        i := MaxInt
      else
        dec(i, offs);
      Result[high(Result)] := Copy(CSV, offs, i);
      exit;
    end;
    Result[high(Result)] := Copy(CSV, offs, i - offs);
    offs := i + length(Sep);
  end;
end;

function AddPrefixToCSV(CSV: PUTF8Char; const Prefix: RawUTF8; Sep: AnsiChar): RawUTF8;
var
  s: RawUTF8;
begin
  GetNextItem(CSV, Sep, result);
  if result = '' then
    exit;
  result := Prefix + result;
  while CSV <> nil do
  begin
    GetNextItem(CSV, Sep, s);
    if s <> '' then
      result := result + ',' + Prefix + s;
  end;
end;

procedure AddToCSV(const Value: RawUTF8; var CSV: RawUTF8; const Sep: RawUTF8);
begin
  if CSV = '' then
    CSV := Value
  else
    CSV := CSV + Sep + Value;
end;

function RenameInCSV(const OldValue, NewValue: RawUTF8; var CSV: RawUTF8;
  const Sep: RawUTF8): boolean;
var
  pattern: RawUTF8;
  i, j: integer;
begin
  result := OldValue = NewValue;
  i := length(OldValue);
  if result or (length(Sep) <> 1) or (length(CSV) < i) or
     (PosEx(Sep, OldValue) > 0) or (PosEx(Sep, NewValue) > 0) then
    exit;
  if CompareMem(pointer(OldValue), pointer(CSV), i) and // first (or unique) item
    ((CSV[i + 1] = Sep[1]) or (CSV[i + 1] = #0)) then
    i := 1
  else
  begin
    j := 1;
    pattern := Sep + OldValue;
    repeat
      i := PosEx(pattern, CSV, j);
      if i = 0 then
        exit;
      j := i + length(pattern);
    until (CSV[j] = Sep[1]) or (CSV[j] = #0);
    inc(i);
  end;
  delete(CSV, i, length(OldValue));
  insert(NewValue, CSV, i);
  result := true;
end;

function RawUTF8ArrayToCSV(const Values: array of RawUTF8; const Sep: RawUTF8): RawUTF8;
var
  i, len, seplen, L: Integer;
  P: PAnsiChar;
begin
  result := '';
  if high(Values) < 0 then
    exit;
  seplen := length(Sep);
  len := seplen * high(Values);
  for i := 0 to high(Values) do
    inc(len, length(Values[i]));
  FastSetString(result, nil, len);
  P := pointer(result);
  i := 0;
  repeat
    L := length(Values[i]);
    if L > 0 then
    begin
      MoveFast(pointer(Values[i])^, P^, L);
      inc(P, L);
    end;
    if i = high(Values) then
      Break;
    if seplen > 0 then
    begin
      MoveSmall(pointer(Sep), P, seplen);
      inc(P, seplen);
    end;
    inc(i);
  until false;
end;

function RawUTF8ArrayToQuotedCSV(const Values: array of RawUTF8;
  const Sep: RawUTF8; Quote: AnsiChar): RawUTF8;
var
  i: integer;
  tmp: TRawUTF8DynArray;
begin
  SetLength(tmp, length(Values));
  for i := 0 to High(Values) do
    tmp[i] := QuotedStr(Values[i], Quote);
  result := RawUTF8ArrayToCSV(tmp, Sep);
end;


{ ************ TBaseWriter parent class for Text Generation }

{ TBaseWriter }

constructor TBaseWriter.Create(aStream: TStream; aBufSize: integer);
begin
  SetStream(aStream);
  if aBufSize < 256 then
    aBufSize := 256;
  SetBuffer(nil, aBufSize);
end;

constructor TBaseWriter.Create(aStream: TStream; aBuf: pointer; aBufSize: integer);
begin
  SetStream(aStream);
  SetBuffer(aBuf, aBufSize);
end;

constructor TBaseWriter.CreateOwnedFileStream(
  const aFileName: TFileName; aBufSize: integer);
begin
  DeleteFile(aFileName);
  Create(TFileStream.Create(aFileName, fmCreate or fmShareDenyWrite), aBufSize);
  Include(fCustomOptions, twoStreamIsOwned);
end;

constructor TBaseWriter.CreateOwnedStream(aBuf: pointer; aBufSize: integer);
begin
  SetStream(TRawByteStringStream.Create);
  SetBuffer(aBuf, aBufSize);
  Include(fCustomOptions, twoStreamIsOwned);
end;

constructor TBaseWriter.CreateOwnedStream(aBufSize: integer);
begin
  Create(TRawByteStringStream.Create, aBufSize);
  Include(fCustomOptions, twoStreamIsOwned);
end;

constructor TBaseWriter.CreateOwnedStream(
  var aStackBuf: TTextWriterStackBuffer; aBufSize: integer);
begin
  if aBufSize > SizeOf(aStackBuf) then // too small -> allocate on heap
    CreateOwnedStream(aBufSize)
  else
    CreateOwnedStream(@aStackBuf, SizeOf(aStackBuf));
end;

destructor TBaseWriter.Destroy;
begin
  if twoStreamIsOwned in fCustomOptions then
    fStream.Free;
  if not (twoBufferIsExternal in fCustomOptions) then
    FreeMem(fTempBuf);
  inherited;
end;

procedure TBaseWriter.Add(const Format: RawUTF8; const Values: array of const;
  Escape: TTextWriterKind; WriteObjectOptions: TTextWriterWriteObjectOptions);
var
  tmp: RawUTF8;
begin
  // basic implementation: see faster and more complete version in TTextWriter
  FormatUTF8(Format, Values, tmp);
  case Escape of
    twNone:
      AddString(tmp);
    twOnSameLine:
      AddOnSameLine(pointer(tmp)); // minimalistic version for TSynLog
    twJSONEscape:
      raise ESynException.CreateUTF8('%.Add(twJSONEscape) unimplemented: use TTextWriter', [self]);
  end;
end;

procedure TBaseWriter.AddVariant(const Value: variant; Escape: TTextWriterKind;
  WriteOptions: TTextWriterWriteObjectOptions);
begin
  raise ESynException.CreateUTF8('%.AddVariant unimplemented: use TTextWriter', [self]);
end;

procedure TBaseWriter.AddTypedJSON(Value, TypeInfo: pointer;
  WriteOptions: TTextWriterWriteObjectOptions);
begin
  raise ESynException.CreateUTF8('%.AddTypedJSON unimplemented: use TTextWriter', [self]);
end;

function TBaseWriter.{%H-}AddJSONReformat(JSON: PUTF8Char;
  Format: TTextWriterJSONFormat; EndOfObject: PUTF8Char): PUTF8Char;
begin
  raise ESynException.CreateUTF8('%.AddJSONReformat unimplemented: use TTextWriter', [self]);
end;

procedure TBaseWriter.AddShorter(const Text: TShort8);
var
  P, S: PUTF8Char;
begin
  P := B;
  if P >= BEnd then
    // BEnd is 16 bytes before end of buffer -> 8 chars OK
    P := FlushToStream;
  S := @Text; // better code generation when inlined on FPC
  inc(B, ord(S[0]));
  PInt64(P + 1)^ := PInt64(S + 1)^;
end;

procedure TBaseWriter.AddNull;
var
  P: PUTF8Char;
begin
  P := B;
  if P >= BEnd then
    P := FlushToStream;
  PCardinal(P + 1)^ := NULL_LOW;
  inc(B, 4);
end;

procedure TBaseWriter.WriteObject(Value: TObject; Options: TTextWriterWriteObjectOptions);
begin
  if Value <> nil then
    AddTypedJSON(@Value, Value.ClassInfo, Options)
  else
    AddNull;
end;

procedure TBaseWriter.AddObjArrayJSON(const aObjArray;
  aOptions: TTextWriterWriteObjectOptions);
var
  i: PtrInt;
  a: TObjectDynArray absolute aObjArray;
begin
  Add('[');
  for i := 0 to length(a) - 1 do
  begin
    WriteObject(a[i], aOptions);
    Add(',');
  end;
  CancelLastComma;
  Add(']');
end;

function TBaseWriter.GetTextLength: PtrUInt;
begin
  if self = nil then
    result := 0
  else
    result := PtrUInt(B - fTempBuf + 1) + fTotalFileSize - fInitialStreamPosition;
end;

var
  DefaultTextWriterTrimEnum: boolean;
  
class procedure TBaseWriter.SetDefaultEnumTrim(aShouldTrimEnumsAsText: boolean);
begin
  DefaultTextWriterTrimEnum := aShouldTrimEnumsAsText;
end;

procedure TBaseWriter.SetBuffer(aBuf: pointer; aBufSize: integer);
begin
  if aBufSize <= 16 then
    raise ESynException.CreateUTF8('%.SetBuffer(size=%)', [self, aBufSize]);
  if aBuf = nil then
    GetMem(fTempBuf, aBufSize)
  else
  begin
    fTempBuf := aBuf;
    Include(fCustomOptions, twoBufferIsExternal);
  end;
  fTempBufSize := aBufSize;
  B := fTempBuf - 1; // Add() methods will append at B+1
  BEnd := fTempBuf + fTempBufSize - 16; // -16 to avoid buffer overwrite/overread
  if DefaultTextWriterTrimEnum then
    Include(fCustomOptions, twoTrimLeftEnumSets);
end;

procedure TBaseWriter.SetStream(aStream: TStream);
begin
  if fStream <> nil then
    if twoStreamIsOwned in fCustomOptions then
    begin
      FreeAndNil(fStream);
      Exclude(fCustomOptions, twoStreamIsOwned);
    end;
  if aStream <> nil then
  begin
    fStream := aStream;
    fInitialStreamPosition := fStream.Position;
    fTotalFileSize := fInitialStreamPosition;
  end;
end;

procedure TBaseWriter.FlushFinal;
begin
  Include(fCustomOptions, twoFlushToStreamNoAutoResize);
  FlushToStream;
end;

function TBaseWriter.FlushToStream: PUTF8Char;
var
  i: PtrInt;
  s: PtrUInt;
begin
  i := B - fTempBuf + 1;
  if i > 0 then
  begin
    if Assigned(fOnFlushToStream) then
      fOnFlushToStream(fTempBuf, i);
    fStream.WriteBuffer(fTempBuf^, i);
    inc(fTotalFileSize, i);
    if not (twoFlushToStreamNoAutoResize in fCustomOptions) then
    begin
      s := fTotalFileSize - fInitialStreamPosition;
      if (fTempBufSize < 49152) and (s > PtrUInt(fTempBufSize) * 4) then
        s := fTempBufSize * 2 // tune small (stack-alloc?) buffer
      else if (fTempBufSize < 1 shl 20) and (s > 40 shl 20) then
        s := 1 shl 20 // 40MB -> 1MB buffer
      else
        s := 0;
      if s > 0 then
      begin
        fTempBufSize := s;
        if twoBufferIsExternal in fCustomOptions then // use heap, not stack
          exclude(fCustomOptions, twoBufferIsExternal)
        else
          FreeMem(fTempBuf); // with big content comes bigger buffer
        GetMem(fTempBuf, fTempBufSize);
        BEnd := fTempBuf + (fTempBufSize - 16);
      end;
    end;
    B := fTempBuf - 1;
  end;
  result := B;
end;

procedure TBaseWriter.ForceContent(const text: RawUTF8);
begin
  CancelAll;
  if (fInitialStreamPosition = 0) and fStream.InheritsFrom(TRawByteStringStream) then
    TRawByteStringStream(fStream).DataString := text
  else
    fStream.WriteBuffer(pointer(text)^, length(text));
  fTotalFileSize := fInitialStreamPosition + cardinal(length(text));
end;

procedure TBaseWriter.SetText(out result: RawUTF8; reformat: TTextWriterJSONFormat);
var
  Len: cardinal;
begin
  FlushFinal;
  Len := fTotalFileSize - fInitialStreamPosition;
  if Len = 0 then
    exit
  else if fStream.InheritsFrom(TRawByteStringStream) then
    TRawByteStringStream(fStream).GetAsText(fInitialStreamPosition, Len, result)
  else if fStream.InheritsFrom(TCustomMemoryStream) then
    with TCustomMemoryStream(fStream) do
      FastSetString(result, PAnsiChar(Memory) + fInitialStreamPosition, Len)
  else
  begin
    FastSetString(result, nil, Len);
    fStream.Seek(fInitialStreamPosition, soBeginning);
    fStream.Read(pointer(result)^, Len);
  end;
  if reformat <> jsonCompact then
  begin
    // reformat using the very same instance
    CancelAll;
    AddJSONReformat(pointer(result), reformat, nil);
    SetText(result);
  end;
end;

function TBaseWriter.Text: RawUTF8;
begin
  SetText(result);
end;

procedure TBaseWriter.CancelAll;
begin
  if self = nil then
    exit; // avoid GPF
  if fTotalFileSize <> 0 then
    fTotalFileSize := fStream.Seek(fInitialStreamPosition, soBeginning);
  B := fTempBuf - 1;
end;

procedure TBaseWriter.CancelLastChar(aCharToCancel: AnsiChar);
begin
  if (B >= fTempBuf) and (B^ = aCharToCancel) then
    dec(B);
end;

procedure TBaseWriter.CancelLastChar;
begin
  if B >= fTempBuf then // Add() methods append at B+1
    dec(B);
end;

procedure TBaseWriter.CancelLastComma;
var
  P: PUTF8Char;
begin
  P := B;
  if (P >= fTempBuf) and (P^ = ',') then
    dec(B);
end;

function TBaseWriter.LastChar: AnsiChar;
begin
  if B >= fTempBuf then
    result := B^
  else
    result := #0;
end;

function TBaseWriter.PendingBytes: PtrUInt;
begin
  result := B - fTempBuf + 1;
end;

procedure TBaseWriter.Add(c: AnsiChar);
var
  P: PUTF8Char;
begin
  P := B;
  if P >= BEnd then
    P := FlushToStream;
  P[1] := c;
  inc(B);
end;

procedure TBaseWriter.AddOnce(c: AnsiChar);
var
  P: PUTF8Char;
begin
  P := B;
  if (P >= fTempBuf) and (P^ = c) then
    exit; // no duplicate
  if P >= BEnd then
    P := FlushToStream;
  P[1] := c;
  inc(B);
end;

procedure TBaseWriter.Add(c1, c2: AnsiChar);
var
  P: PUTF8Char;
begin
  P := B;
  if P >= BEnd then
    P := FlushToStream;
  P[1] := c1;
  P[2] := c2;
  inc(B, 2);
end;

procedure TBaseWriter.Add(Value: PtrInt);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
  Len: PtrInt;
begin
  if BEnd - B <= 23 then
    FlushToStream;
  if PtrUInt(Value) <= high(SmallUInt32UTF8) then
  begin
    P := pointer(SmallUInt32UTF8[Value]);
    Len := PStrLen(P - _STRLEN)^;
  end
  else
  begin
    P := StrInt32(@tmp[23], Value);
    Len := @tmp[23] - P;
  end;
  MoveSmall(P, B + 1, Len);
  inc(B, Len);
end;

{$ifndef CPU64} // Add(Value: PtrInt) already implemented it
procedure TBaseWriter.Add(Value: Int64);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
  Len: integer;
begin
  if BEnd - B <= 24 then
    FlushToStream;
  if Value < 0 then
  begin
    P := StrUInt64(@tmp[23], -Value) - 1;
    P^ := '-';
    Len := @tmp[23] - P;
  end
  else if Value <= high(SmallUInt32UTF8) then
  begin
    P := pointer(SmallUInt32UTF8[Value]);
    Len := PStrLen(P - _STRLEN)^;
  end
  else
  begin
    P := StrUInt64(@tmp[23], Value);
    Len := @tmp[23] - P;
  end;
  MoveSmall(P, B + 1, Len);
  inc(B, Len);
end;
{$endif CPU64}

procedure TBaseWriter.AddCurr64(Value: PInt64);
var
  tmp: array[0..31] of AnsiChar;
  P: PAnsiChar;
  Len: PtrInt;
begin
  if BEnd - B <= 31 then
    FlushToStream;
  P := StrCurr64(@tmp[31], Value^);
  Len := @tmp[31] - P;
  if Len > 4 then
    if P[Len - 1] = '0' then
      if P[Len - 2] = '0' then
        if P[Len - 3] = '0' then
          if P[Len - 4] = '0' then
            dec(Len, 5)
          else
            dec(Len, 3)
        else
          dec(Len, 2)
      else
        dec(Len);
  MoveSmall(P, B + 1, Len);
  inc(B, Len);
end;

procedure TBaseWriter.AddCurr64(const Value: TSynCurrency);
begin
  AddCurr64(PInt64(@Value));
end;

procedure TBaseWriter.AddU(Value: cardinal);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
  Len: PtrInt;
begin
  if BEnd - B <= 24 then
    FlushToStream;
  if Value <= high(SmallUInt32UTF8) then
  begin
    P := pointer(SmallUInt32UTF8[Value]);
    Len := PStrLen(P - _STRLEN)^;
  end
  else
  begin
    P := StrUInt32(@tmp[23], Value);
    Len := @tmp[23] - P;
  end;
  MoveSmall(P, B + 1, Len);
  inc(B, Len);
end;

procedure TBaseWriter.AddQ(Value: QWord);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
  Len: PtrInt;
begin
  if BEnd - B <= 32 then
    FlushToStream;
  if Value <= high(SmallUInt32UTF8) then
  begin
    P := pointer(SmallUInt32UTF8[Value]);
    Len := PStrLen(P - _STRLEN)^;
  end
  else
  begin
    P := StrUInt64(@tmp[23], Value);
    Len := @tmp[23] - P;
  end;
  MoveSmall(P, B + 1, Len);
  inc(B, Len);
end;

procedure TBaseWriter.AddQHex(Value: Qword);
begin
  AddBinToHexDisplayLower(@Value, SizeOf(Value), '"');
end;

procedure TBaseWriter.Add(Value: Extended; precision: integer; noexp: boolean);
var
  tmp: ShortString;
begin
  AddShort(ExtendedToJSON(tmp, Value, precision, noexp)^);
end;

procedure TBaseWriter.AddDouble(Value: double; noexp: boolean);
var
  tmp: ShortString;
begin
  AddShort(DoubleToJSON(tmp, Value, noexp)^);
end;

procedure TBaseWriter.AddSingle(Value: single; noexp: boolean);
var
  tmp: ShortString;
begin
  AddShort(ExtendedToJSON(tmp, Value, SINGLE_PRECISION, noexp)^);
end;

procedure TBaseWriter.Add(Value: boolean);
begin
  AddShorter(BOOL_STR[Value]);
end;

procedure TBaseWriter.AddFloatStr(P: PUTF8Char);
begin
  if StrLen(P) > 127 then
    exit; // clearly invalid input
  if BEnd - B <= 127 then
    FlushToStream;
  inc(B);
  if P <> nil then
    B := FloatStrCopy(P, B) - 1
  else
    B^ := '0';
end;

procedure TBaseWriter.Add(Value: PGUID; QuotedChar: AnsiChar);
begin
  if BEnd - B <= 38 then
    FlushToStream;
  inc(B);
  if QuotedChar <> #0 then
  begin
    B^ := QuotedChar;
    inc(B);
  end;
  GUIDToText(B, pointer(Value));
  inc(B, 36);
  if QuotedChar <> #0 then
    B^ := QuotedChar
  else
    dec(B);
end;

procedure TBaseWriter.AddCR;
var
  P: PUTF8Char;
begin
  P := B;
  if P >= BEnd then
    P := FlushToStream;
  PWord(P + 1)^ := 13 + 10 shl 8; // CR + LF
  inc(B, 2);
end;

procedure TBaseWriter.AddCRAndIndent;
var
  ntabs: cardinal;
begin
  if B^ = #9 then
    exit; // we most probably just added an indentation level
  ntabs := fHumanReadableLevel;
  if ntabs >= cardinal(fTempBufSize) then
    ntabs := 0; // avoid buffer overflow
  if BEnd - B <= PtrInt(ntabs) then
    FlushToStream;
  PWord(B + 1)^ := 13 + 10 shl 8; // CR + LF
  FillCharFast(B[3], ntabs, 9);   // #9=tab
  inc(B, ntabs + 2);
end;

procedure TBaseWriter.AddChars(aChar: AnsiChar; aCount: integer);
var
  n: integer;
begin
  repeat
    n := BEnd - B;
    if aCount < n then
      n := aCount
    else
      FlushToStream; // loop to avoid buffer overflow
    FillCharFast(B[1], n, ord(aChar));
    inc(B, n);
    dec(aCount, n);
  until aCount <= 0;
end;

procedure TBaseWriter.Add2(Value: PtrUInt);
begin
  if B >= BEnd then
    FlushToStream;
  if Value > 99 then
    PCardinal(B + 1)^ := $3030 + ord(',') shl 16
  else     // '00,' if overflow
    PCardinal(B + 1)^ := TwoDigitLookupW[Value] + ord(',') shl 16;
  inc(B, 3);
end;

function Value3Digits(V: PtrUInt; P: PUTF8Char; W: PWordArray): PtrUInt;
  {$ifdef HASINLINE} inline; {$endif}
begin
  result := V div 100;
  PWord(P + 1)^ := W[V - result * 100];
  V := result;
  result := result div 10;
  P^ := AnsiChar(V - result * 10 + 48);
end;

procedure TBaseWriter.Add3(Value: PtrUInt);
var
  V: PtrUInt;
begin
  if B >= BEnd then
    FlushToStream;
  if Value > 999 then
    PCardinal(B + 1)^ := $303030
  else
  begin// '0000,' if overflow
    V := Value div 10;
    PCardinal(B + 1)^ := TwoDigitLookupW[V] + (Value - V * 10 + 48) shl 16;
  end;
  inc(B, 4);
  B^ := ',';
end;

procedure TBaseWriter.Add4(Value: PtrUInt);
begin
  if B >= BEnd then
    FlushToStream;
  if Value > 9999 then
    PCardinal(B + 1)^ := $30303030
  else // '0000,' if overflow
    YearToPChar(Value, B + 1);
  inc(B, 5);
  B^ := ',';
end;

procedure TBaseWriter.AddCurrentLogTime(LocalTime: boolean);
var
  time: TSynSystemTime;
begin
  time.FromNow(LocalTime);
  time.AddLogTime(self);
end;

procedure TBaseWriter.AddCurrentNCSALogTime(LocalTime: boolean);
var
  time: TSynSystemTime;
begin
  time.FromNow(LocalTime);
  if BEnd - B <= 21 then
    FlushToStream;
  inc(B, time.ToNCSAText(B + 1));
end;
procedure TBaseWriter.AddMicroSec(MS: cardinal);
var
  W: PWordArray;
begin // in 00.000.000 TSynLog format
  if B >= BEnd then
    FlushToStream;
  B[3] := '.';
  B[7] := '.';
  inc(B);
  W := @TwoDigitLookupW;
  MS := Value3Digits(Value3Digits(MS, B + 7, W), B + 3, W);
  if MS > 99 then
    MS := 99;
  PWord(B)^ := W[MS];
  inc(B, 9);
end;

procedure TBaseWriter.AddNoJSONEscape(P: Pointer);
begin
  AddNoJSONEscape(P, StrLen(PUTF8Char(P)));
end;

procedure TBaseWriter.AddNoJSONEscape(P: Pointer; Len: PtrInt);
var
  i: PtrInt;
begin
  if (P <> nil) and (Len > 0) then
  begin
    inc(B); // allow CancelLastChar
    repeat
      i := BEnd - B; // guess biggest size to be added into buf^ at once
      if Len < i then
        i := Len;
      // add UTF-8 bytes
      if i > 0 then
      begin
        MoveFast(P^, B^, i);
        inc(B, i);
      end;
      if i = Len then
        break;
      inc(PByte(P), i);
      dec(Len, i);
      // FlushInc writes B-buf+1 -> special one below:
      i := B - fTempBuf;
      fStream.WriteBuffer(fTempBuf^, i);
      inc(fTotalFileSize, i);
      B := fTempBuf;
    until false;
    dec(B); // allow CancelLastChar
  end;
end;

procedure EngineAppendUTF8(W: TBaseWriter; Engine: TSynAnsiConvert;
  P: PAnsiChar; Len: PtrInt);
var
  tmp: TSynTempBuffer;
begin // explicit conversion using a temporary buffer on stack
  Len := Engine.AnsiBufferToUTF8(tmp.Init(Len * 3), P, Len) - PUTF8Char({%H-}tmp.buf);
  W.AddNoJSONEscape(tmp.buf, Len);
  tmp.Done;
end;

procedure TBaseWriter.AddNoJSONEscape(P: PAnsiChar; Len: PtrInt; CodePage: cardinal);
var
  B: PAnsiChar;
begin
  if Len > 0 then
    case CodePage of
      CP_UTF8, CP_RAWBYTESTRING, CP_SQLRAWBLOB:
        AddNoJSONEscape(P, Len);
      CP_UTF16:
        AddNoJSONEscapeW(PWord(P), 0);
    else
      begin
        // first handle trailing 7 bit ASCII chars, by quad
        B := P;
        if Len >= 4 then
          repeat
            if PCardinal(P)^ and $80808080 <> 0 then
              break; // break on first non ASCII quad
            inc(P, 4);
            dec(Len, 4);
          until Len < 4;
        if (Len > 0) and (P^ < #128) then
          repeat
            inc(P);
            dec(Len);
          until (Len = 0) or (P^ >= #127);
        if P <> B then
          AddNoJSONEscape(B, P - B);
        if Len > 0 then
          // rely on explicit conversion for all remaining ASCII characters
          EngineAppendUTF8(self, TSynAnsiConvert.Engine(CodePage), P, Len);
      end;
    end;
end;

procedure TBaseWriter.AddNoJSONEscapeUTF8(const text: RawByteString);
begin
  AddNoJSONEscape(pointer(text), length(text));
end;

procedure TBaseWriter.AddRawJSON(const json: RawJSON);
begin
  if json = '' then
    AddNull
  else
    AddNoJSONEscape(pointer(json), length(json));
end;

procedure TBaseWriter.AddNoJSONEscapeString(const s: string);
begin
  if s <> '' then
    {$ifdef UNICODE}
    AddNoJSONEscapeW(pointer(s), 0);
    {$else}
    AddNoJSONEscape(pointer(s), length(s), CurrentAnsiConvert.CodePage);
    {$endif UNICODE}
end;

procedure TBaseWriter.AddNoJSONEscapeW(WideChar: PWord; WideCharCount: integer);
var
  PEnd: PtrUInt;
begin
  if WideChar = nil then
    exit;
  if WideCharCount = 0 then
    repeat
      if B >= BEnd then
        FlushToStream;
      if WideChar^ = 0 then
        break;
      if WideChar^ <= 126 then
      begin
        B[1] := AnsiChar(ord(WideChar^));
        inc(WideChar);
        inc(B);
      end
      else
        inc(B, UTF16CharToUtf8(B + 1, WideChar));
    until false
  else
  begin
    PEnd := PtrUInt(WideChar) + PtrUInt(WideCharCount) * SizeOf(WideChar^);
    repeat
      if B >= BEnd then
        FlushToStream;
      if WideChar^ = 0 then
        break;
      if WideChar^ <= 126 then
      begin
        B[1] := AnsiChar(ord(WideChar^));
        inc(WideChar);
        inc(B);
        if PtrUInt(WideChar) < PEnd then
          continue
        else
          break;
      end;
      inc(B, UTF16CharToUtf8(B + 1, WideChar));
      if PtrUInt(WideChar) < PEnd then
        continue
      else
        break;
    until false;
  end;
end;

procedure TBaseWriter.AddProp(PropName: PUTF8Char; PropNameLen: PtrInt);
begin
  if PropNameLen <= 0 then
    exit; // paranoid check
  if BEnd - B <= PropNameLen then
    FlushToStream;
  if twoForceJSONExtended in CustomOptions then
  begin
    MoveSmall(PropName, B + 1, PropNameLen);
    inc(B, PropNameLen + 1);
    B^ := ':';
  end
  else
  begin
    B[1] := '"';
    MoveSmall(PropName, B + 2, PropNameLen);
    inc(B, PropNameLen + 2);
    PWord(B)^ := ord('"') + ord(':') shl 8;
    inc(B);
  end;
end;

procedure TBaseWriter.AddPropName(const PropName: ShortString);
begin
  AddProp(@PropName[1], ord(PropName[0]));
end;

procedure TBaseWriter.AddFieldName(const FieldName: RawUTF8);
begin
  AddProp(Pointer(FieldName), length(FieldName));
end;

procedure TBaseWriter.AddClassName(aClass: TClass);
begin
  if aClass <> nil then
    AddShort(ClassNameShort(aClass)^);
end;

procedure TBaseWriter.AddInstanceName(Instance: TObject; SepChar: AnsiChar);
begin
  Add('"');
  if Instance = nil then
    AddShorter('void')
  else
    AddShort(ClassNameShort(Instance)^);
  Add('(');
  AddBinToHexDisplayMinChars(@Instance, SizeOf(Instance));
  Add(')', '"');
  if SepChar <> #0 then
    Add(SepChar);
end;

procedure TBaseWriter.AddInstancePointer(Instance: TObject; SepChar: AnsiChar;
  IncludeUnitName, IncludePointer: boolean);
begin
  if IncludeUnitName and Assigned(ClassUnit) then
  begin
    AddShort(ClassUnit(PClass(Instance)^)^);
    Add('.');
  end;
  AddShort(PPShortString(PPAnsiChar(Instance)^ + vmtClassName)^^);
  if IncludePointer then
  begin
    Add('(');
    AddBinToHexDisplayMinChars(@Instance,SizeOf(Instance));
    Add(')');
  end;
  if SepChar<>#0 then
    Add(SepChar);
end;

procedure TBaseWriter.AddShort(const Text: ShortString);
var
  L: PtrInt;
begin
  L := ord(Text[0]);
  if L = 0 then
    exit;
  if BEnd - B <= L then
    FlushToStream;
  MoveFast(Text[1], B[1], L);
  inc(B, L);
end;

procedure TBaseWriter.AddLine(const Text: shortstring);
var
  L: PtrInt;
begin
  L := ord(Text[0]);
  if BEnd - B <= L then
    FlushToStream;
  inc(B);
  if L > 0 then
  begin
    MoveFast(Text[1], B^, L);
    inc(B, L);
  end;
  PWord(B)^ := 13 + 10 shl 8; // CR + LF
  inc(B);
end;

procedure TBaseWriter.AddOnSameLine(P: PUTF8Char);
var
  D: PUTF8Char;
  c: AnsiChar;
begin
  if P <> nil then
  begin
    D := B + 1;
    if P^ <> #0 then
      repeat
        if D >= BEnd then
          D := FlushToStream + 1;
        c := P^;
        if c < ' ' then
          if c = #0 then
            break
          else
            c := ' ';
        D^ := c;
        inc(P);
        inc(D);
      until false;
    B := D - 1;
  end;
end;

procedure TBaseWriter.AddOnSameLine(P: PUTF8Char; Len: PtrInt);
var
  D: PUTF8Char;
  c: AnsiChar;
begin
  if (P <> nil) and (Len > 0) then
  begin
    D := B + 1;
    repeat
      if D >= BEnd then
        D := FlushToStream + 1;
      c := P^;
      if c < ' ' then
        c := ' ';
      D^ := c;
      inc(D);
      inc(P);
      dec(Len);
    until Len = 0;
    B := D - 1;
  end;
end;

procedure TBaseWriter.AddOnSameLineW(P: PWord; Len: PtrInt);
var
  PEnd: PtrUInt;
  c: cardinal;
begin
  if P = nil then
    exit;
  if Len = 0 then
    PEnd := 0
  else
    PEnd := PtrUInt(P) + PtrUInt(Len) * SizeOf(WideChar);
  while (Len = 0) or (PtrUInt(P) < PEnd) do
  begin
    if B >= BEnd then
      FlushToStream;
    // escape chars, so that all content will stay on the same text line
    c := P^;
    case c of
      0:
        break;
      1..32:
        begin
          B[1] := ' ';
          inc(B);
          inc(P);
        end;
      33..126:
        begin
          B[1] := AnsiChar(c); // direct store 7 bits ASCII
          inc(B);
          inc(P);
        end;
    else // characters higher than #126 -> UTF-8 encode
      inc(B, UTF16CharToUtf8(B + 1, P));
    end;
  end;
end;

procedure TBaseWriter.AddTrimLeftLowerCase(Text: PShortString);
var
  P: PAnsiChar;
  L: integer;
begin
  L := length(Text^);
  P := @Text^[1];
  while (L > 0) and (P^ in ['a'..'z']) do
  begin
    inc(P);
    dec(L);
  end;
  if L = 0 then
    AddShort(Text^)
  else
    AddNoJSONEscape(P, L);
end;

procedure TBaseWriter.AddTrimSpaces(const Text: RawUTF8);
begin
  AddTrimSpaces(pointer(Text));
end;

procedure TBaseWriter.AddTrimSpaces(P: PUTF8Char);
var
  c: AnsiChar;
begin
  if P <> nil then
    repeat
      c := P^;
      inc(P);
      if c > ' ' then
        Add(c);
    until c = #0;
end;

procedure TBaseWriter.AddReplace(Text: PUTF8Char; Orig, Replaced: AnsiChar);
begin
  if Text <> nil then
    while Text^ <> #0 do
    begin
      if Text^ = Orig then
        Add(Replaced)
      else
        Add(Text^);
      inc(Text);
    end;
end;

procedure TBaseWriter.AddByteToHex(Value: byte);
begin
  if B >= BEnd then
    FlushToStream;
  ByteToHex(PAnsiChar(B) + 1, Value);
  inc(B, 2);
end;

procedure TBaseWriter.AddInt18ToChars3(Value: cardinal);
begin
  if B >= BEnd then
    FlushToStream;
  PCardinal(B + 1)^ := ((Value shr 12) and $3f) or ((Value shr 6) and $3f) shl 8 or
                        (Value and $3f) shl 16 + $202020;
  inc(B, 3);
end;

procedure TBaseWriter.AddTimeLog(Value: PInt64; QuoteChar: AnsiChar);
begin
  if BEnd - B <= 31 then
    FlushToStream;
  B := PTimeLogBits(Value)^.Text(B + 1, true, 'T', QuoteChar) - 1;
end;

procedure TBaseWriter.AddUnixTime(Value: PInt64; QuoteChar: AnsiChar);
var
  DT: TDateTime;
begin // inlined UnixTimeToDateTime()
  DT := Value^ / SecsPerDay + UnixDateDelta;
  AddDateTime(@DT, 'T', QuoteChar, {withms=}false, {dateandtime=}true);
end;

procedure TBaseWriter.AddUnixMSTime(Value: PInt64; WithMS: boolean;
  QuoteChar: AnsiChar);
var
  DT: TDateTime;
begin // inlined UnixMSTimeToDateTime()
  DT := Value^ / MSecsPerDay + UnixDateDelta;
  AddDateTime(@DT, 'T', QuoteChar, WithMS, {dateandtime=}true);
end;

procedure TBaseWriter.AddDateTime(Value: PDateTime; FirstChar: AnsiChar;
  QuoteChar: AnsiChar; WithMS, AlwaysDateAndTime: boolean);
var
  T: TSynSystemTime;
begin
  if (Value^ = 0) and (QuoteChar = #0) then
    exit;
  if BEnd - B <= 25 then
    FlushToStream;
  inc(B);
  if QuoteChar <> #0 then
    B^ := QuoteChar
  else
    dec(B);
  if Value^ <> 0 then
  begin
    inc(B);
    if AlwaysDateAndTime or (trunc(Value^) <> 0) then
    begin
      T.FromDate(Date);
      B := DateToIso8601PChar(B, true, T.Year, T.Month, T.Day);
    end;
    if AlwaysDateAndTime or (frac(Value^) <> 0) then
    begin
      T.FromTime(Value^);
      B := TimeToIso8601PChar(B, true, T.Hour, T.Minute, T.Second, T.MilliSecond,
        FirstChar, WithMS);
    end;
    dec(B);
  end;
  if QuoteChar <> #0 then
  begin
    inc(B);
    B^ := QuoteChar;
  end;
end;

procedure TBaseWriter.AddDateTime(const Value: TDateTime; WithMS: boolean);
begin
  if Value = 0 then
    exit;
  if BEnd - B <= 23 then
    FlushToStream;
  inc(B);
  if trunc(Value) <> 0 then
    B := DateToIso8601PChar(Value, B, true);
  if frac(Value) <> 0 then
    B := TimeToIso8601PChar(Value, B, true, 'T', WithMS);
  dec(B);
end;

procedure TBaseWriter.AddString(const Text: RawUTF8);
var
  L: PtrInt;
begin
  L := PtrInt(Text);
  if L = 0 then
    exit;
  L := PStrLen(L - _STRLEN)^;
  if L < fTempBufSize then
  begin
    if BEnd - B <= L then
      FlushToStream;
    MoveFast(pointer(Text)^, B[1], L);
    inc(B, L);
  end
  else
    AddNoJSONEscape(pointer(Text), L);
end;

procedure TBaseWriter.AddStringCopy(const Text: RawUTF8; start, len: PtrInt);
var
  L: PtrInt;
begin
  L := PtrInt(Text);
  if (len <= 0) or (L = 0) then
    exit;
  if start < 0 then
    start := 0
  else
    dec(start);
  L := PStrLen(L - _STRLEN)^;
  dec(L, start);
  if L > 0 then
  begin
    if len < L then
      L := len;
    AddNoJSONEscape(@PByteArray(Text)[start], L);
  end;
end;

procedure TBaseWriter.AddStrings(const Text: array of RawUTF8);
var
  i: PtrInt;
begin
  for i := 0 to high(Text) do
    AddString(Text[i]);
end;

procedure TBaseWriter.AddStrings(const Text: RawUTF8; count: integer);
var
  i, L: integer;
begin
  L := length(Text);
  if L > 0 then
    if L * count > fTempBufSize then
      for i := 1 to count do
        AddString(Text)
    else
    begin
      if BEnd - B <= L * count then
        FlushToStream;
      for i := 1 to count do
      begin
        MoveFast(pointer(Text)^, B[1], L);
        inc(B, L);
      end;
    end;
end;

procedure TBaseWriter.AddBinToHexDisplay(Bin: pointer; BinBytes: integer);
begin
  if cardinal(BinBytes * 2 - 1) >= cardinal(fTempBufSize) then
    exit;
  if BEnd - B <= BinBytes * 2 then
    FlushToStream;
  BinToHexDisplay(Bin, PAnsiChar(B + 1), BinBytes);
  inc(B, BinBytes * 2);
end;

procedure TBaseWriter.AddBinToHexDisplayLower(Bin: pointer; BinBytes: integer;
  QuotedChar: AnsiChar);
begin
  if cardinal(BinBytes * 2 + 1) >= cardinal(fTempBufSize) then
    exit;
  if BEnd - B <= BinBytes * 2 then
    FlushToStream;
  inc(B);
  if QuotedChar <> #0 then
  begin
    B^ := QuotedChar;
    inc(B);
  end;
  BinToHexDisplayLower(Bin, pointer(B), BinBytes);
  inc(B, BinBytes * 2);
  if QuotedChar <> #0 then
    B^ := QuotedChar
  else
    dec(B);
end;

procedure TBaseWriter.AddBinToHexDisplayQuoted(Bin: pointer; BinBytes: integer);
begin
  AddBinToHexDisplayLower(Bin, BinBytes, '"');
end;

procedure TBaseWriter.AddBinToHexDisplayMinChars(Bin: pointer; BinBytes: PtrInt;
  QuotedChar: AnsiChar);
begin
  if BinBytes <= 0 then
    BinBytes := 0
  else
  begin
    repeat // append hexa chars up to the last non zero byte
      dec(BinBytes);
    until (BinBytes = 0) or (PByteArray(Bin)[BinBytes] <> 0);
    inc(BinBytes);
  end;
  AddBinToHexDisplayLower(Bin, BinBytes, QuotedChar);
end;

procedure TBaseWriter.AddPointer(P: PtrUInt; QuotedChar: AnsiChar);
begin
  AddBinToHexDisplayMinChars(@P, SizeOf(P), QuotedChar);
end;

procedure TBaseWriter.AddBinToHex(Bin: Pointer; BinBytes: integer);
var
  ChunkBytes: PtrInt;
begin
  if BinBytes <= 0 then
    exit;
  if B >= BEnd then
    FlushToStream;
  inc(B);
  repeat
    // guess biggest size to be added into buf^ at once
    ChunkBytes := (BEnd - B) shr 1; // div 2, *2 -> two hexa chars per byte
    if BinBytes < ChunkBytes then
      ChunkBytes := BinBytes;
    // add hexa characters
    mormot.core.text.BinToHex(PAnsiChar(Bin), PAnsiChar(B), ChunkBytes);
    inc(B, ChunkBytes * 2);
    inc(PByte(Bin), ChunkBytes);
    dec(BinBytes, ChunkBytes);
    if BinBytes = 0 then
      break;
    // Flush writes B-buf+1 -> special one below:
    ChunkBytes := B - fTempBuf;
    fStream.WriteBuffer(fTempBuf^, ChunkBytes);
    inc(fTotalFileSize, ChunkBytes);
    B := fTempBuf;
  until false;
  dec(B); // allow CancelLastChar
end;

procedure TBaseWriter.AddQuotedStr(Text: PUTF8Char; Quote: AnsiChar; TextMaxLen: PtrInt);
var
  c: AnsiChar;
  P: PUTF8Char;
begin
  if TextMaxLen <= 0 then
    TextMaxLen := maxInt
  else if TextMaxLen > 5 then
    dec(TextMaxLen, 5);
  if B >= BEnd then
    FlushToStream;
  P := B + 1;
  P^ := Quote;
  inc(P);
  if Text <> nil then
    repeat
      if P < BEnd then
      begin
        dec(TextMaxLen);
        if TextMaxLen <> 0 then
        begin
          c := Text^;
          inc(Text);
          if c = #0 then
            break;
          P^ := c;
          inc(P);
          if c <> Quote then
            continue;
          P^ := c;
          inc(P);
        end
        else
        begin
          PCardinal(P)^ := ord('.') + ord('.') shl 8 + ord('.') shl 16;
          inc(P, 3);
          break;
        end;
      end
      else
        P := FlushToStream + 1;
    until false;
  P^ := Quote;
  B := P;
end;

const
  HTML_ESC: array[hfAnyWhere..high(TTextWriterHTMLFormat)] of TSynAnsicharSet = (
    [#0, '&', '"', '<', '>'],
    [#0, '&', '<', '>'],
    [#0, '&', '"']);
  XML_ESC: TSynByteSet =
    [0..31, ord('<'), ord('>'), ord('&'), ord('"'), ord('''')];

procedure TBaseWriter.AddHtmlEscape(Text: PUTF8Char; Fmt: TTextWriterHTMLFormat);
var
  B: PUTF8Char;
  esc: ^TSynAnsicharSet;
begin
  if Text = nil then
    exit;
  if Fmt = hfNone then
  begin
    AddNoJSONEscape(Text);
    exit;
  end;
  esc := @HTML_ESC[Fmt];
  repeat
    B := Text;
    while not (Text^ in esc^) do
      inc(Text);
    AddNoJSONEscape(B, Text - B);
    case Text^ of
      #0:
        exit;
      '<':
        AddShorter('&lt;');
      '>':
        AddShorter('&gt;');
      '&':
        AddShorter('&amp;');
      '"':
        AddShorter('&quot;');
    end;
    inc(Text);
  until Text^ = #0;
end;

procedure TBaseWriter.AddHtmlEscape(Text: PUTF8Char; TextLen: PtrInt;
  Fmt: TTextWriterHTMLFormat);
var
  B: PUTF8Char;
  esc: ^TSynAnsicharSet;
begin
  if (Text = nil) or (TextLen <= 0) then
    exit;
  if Fmt = hfNone then
  begin
    AddNoJSONEscape(Text, TextLen);
    exit;
  end;
  inc(TextLen, PtrInt(Text)); // TextLen = final PtrInt(Text)
  esc := @HTML_ESC[Fmt];
  repeat
    B := Text;
    while (PtrUInt(Text) < PtrUInt(TextLen)) and not (Text^ in esc^) do
      inc(Text);
    AddNoJSONEscape(B, Text - B);
    if PtrUInt(Text) = PtrUInt(TextLen) then
      exit;
    case Text^ of
      #0:
        exit;
      '<':
        AddShorter('&lt;');
      '>':
        AddShorter('&gt;');
      '&':
        AddShorter('&amp;');
      '"':
        AddShorter('&quot;');
    end;
    inc(Text);
  until false;
end;

procedure TBaseWriter.AddHtmlEscapeString(const Text: string; Fmt: TTextWriterHTMLFormat);
begin
  AddHtmlEscape(pointer(StringToUTF8(Text)), Fmt);
end;

procedure TBaseWriter.AddHtmlEscapeUTF8(const Text: RawUTF8; Fmt: TTextWriterHTMLFormat);
begin
  AddHtmlEscape(pointer(Text), length(Text), Fmt);
end;

procedure TBaseWriter.AddXmlEscape(Text: PUTF8Char);
var
  i, beg: PtrInt;
  esc: ^TSynByteSet;
begin
  if Text = nil then
    exit;
  esc := @XML_ESC;
  i := 0;
  repeat
    beg := i;
    if not (ord(Text[i]) in esc^) then
    begin
      repeat // it is faster to handle all not-escaped chars at once
        inc(i);
      until ord(Text[i]) in esc^;
      AddNoJSONEscape(Text + beg, i - beg);
    end;
    repeat
      case Text[i] of
        #0:
          exit;
        #1..#8, #11, #12, #14..#31:
          ; // ignore invalid character - see http://www.w3.org/TR/xml/#NT-Char
        #9, #10, #13:
          begin // characters below ' ', #9 e.g. -> // '&#x09;'
            AddShorter('&#x');
            AddByteToHex(ord(Text[i]));
            Add(';');
          end;
        '<':
          AddShorter('&lt;');
        '>':
          AddShorter('&gt;');
        '&':
          AddShorter('&amp;');
        '"':
          AddShorter('&quot;');
        '''':
          AddShorter('&apos;');
      else
        break; // should match XML_ESC[] constant above
      end;
      inc(i);
    until false;
  until false;
end;


{ TEchoWriter }

constructor TEchoWriter.Create(Owner: TBaseWriter);
begin
  fWriter := Owner;
  if Assigned(fWriter.OnFlushToStream) then
    raise ESynException.CreateUTF8('Unexpected %.Create', [self]);
  fWriter.OnFlushToStream := FlushToStream;
end;

destructor TEchoWriter.Destroy;
begin
  if (fWriter <> nil) and (TMethod(fWriter.OnFlushToStream).Data = self) then
    fWriter.OnFlushToStream := nil;
  inherited Destroy;
end;

procedure TEchoWriter.AddEndOfLine(aLevel: TSynLogInfo);
var
  i: PtrInt;
begin
  if twoEndOfLineCRLF in fWriter.CustomOptions then
    fWriter.AddCR
  else
    fWriter.Add(#10);
  if fEchos <> nil then
  begin
    fEchoStart := EchoFlush;
    for i := length(fEchos) - 1 downto 0 do // for MultiEventRemove() below
    try
      fEchos[i](fWriter, aLevel, fEchoBuf);
    except // remove callback in case of exception during echoing in user code
      MultiEventRemove(fEchos, i);
    end;
    fEchoBuf := '';
  end;
end;

procedure TEchoWriter.FlushToStream(Text: PUTF8Char; Len: PtrInt);
begin
  if fEchos <> nil then
  begin
    EchoFlush;
    fEchoStart := 0;
  end;
end;

procedure TEchoWriter.EchoAdd(const aEcho: TOnTextWriterEcho);
begin
  if self <> nil then
    if MultiEventAdd(fEchos, TMethod(aEcho)) then
      if fEchos <> nil then
        fEchoStart := fWriter.B - fWriter.fTempBuf + 1; // ignore any previous buffer
end;

procedure TEchoWriter.EchoRemove(const aEcho: TOnTextWriterEcho);
begin
  if self <> nil then
    MultiEventRemove(fEchos, TMethod(aEcho));
end;

function TEchoWriter.EchoFlush: PtrInt;
var
  L, LI: PtrInt;
  P: PUTF8Char;
begin
  P := fWriter.fTempBuf;
  result := fWriter.B - P + 1;
  L := result - fEchoStart;
  inc(P, fEchoStart);
  while (L > 0) and (P[L - 1] in [#10, #13]) do // trim right CR/LF chars
    dec(L);
  LI := length(fEchoBuf); // fast append to fEchoBuf
  SetLength(fEchoBuf, LI + L);
  MoveFast(P^, PByteArray(fEchoBuf)[LI], L);
end;

procedure TEchoWriter.EchoReset;
begin
  fEchoBuf := '';
end;

function TEchoWriter.GetEndOfLineCRLF: boolean;
begin
  result := twoEndOfLineCRLF in fWriter.CustomOptions;
end;

procedure TEchoWriter.SetEndOfLineCRLF(aEndOfLineCRLF: boolean);
begin
  if aEndOfLineCRLF then
    fWriter.CustomOptions := fWriter.CustomOptions + [twoEndOfLineCRLF]
  else
    fWriter.CustomOptions := fWriter.CustomOptions - [twoEndOfLineCRLF];
end;



function ObjectToJSON(Value: TObject; Options: TTextWriterWriteObjectOptions): RawUTF8;
var
  temp: TTextWriterStackBuffer;
begin
  if Value = nil then
    result := NULL_STR_VAR
  else
    with DefaultTextWriterSerializer.CreateOwnedStream(temp) do
    try
      include(fCustomOptions, twoForceJSONStandard);
      WriteObject(Value, Options);
      SetText(result);
    finally
      Free;
    end;
end;

function ObjectsToJSON(const Names: array of RawUTF8; const Values: array of TObject;
  Options: TTextWriterWriteObjectOptions): RawUTF8;
var
  i, n: PtrInt;
  temp: TTextWriterStackBuffer;
begin
  with DefaultTextWriterSerializer.CreateOwnedStream(temp) do
  try
    n := length(Names);
    Add('{');
    for i := 0 to high(Values) do
      if Values[i] <> nil then
      begin
        if i < n then
          AddFieldName(Names[i])
        else
          AddPropName(ClassNameShort(Values[i])^);
        WriteObject(Values[i], Options);
        Add(',');
      end;
    CancelLastComma;
    Add('}');
    SetText(result);
  finally
    Free;
  end;
end;


{ ************ TRawUTF8DynArray Processing Functions }

function IsZero(const Values: TRawUTF8DynArray): boolean;
var
  i: PtrInt;
begin
  result := false;
  for i := 0 to length(Values) - 1 do
    if Values[i] <> '' then
      exit;
  result := true;
end;

function TRawUTF8DynArrayFrom(const Values: array of RawUTF8): TRawUTF8DynArray;
var
  i: PtrInt;
begin
  Finalize(result);
  SetLength(result, length(Values));
  for i := 0 to high(Values) do
    result[i] := Values[i];
end;

function FindRawUTF8(Values: PRawUTF8; const Value: RawUTF8; ValuesCount: integer;
  CaseSensitive: boolean): integer;
var
  ValueLen: TStrLen;
begin
  dec(ValuesCount);
  ValueLen := length(Value);
  if ValueLen = 0 then
    for result := 0 to ValuesCount do
      if Values^ = '' then
        exit
      else
        inc(Values)
  else if CaseSensitive then
    for result := 0 to ValuesCount do
      if (PtrUInt(Values^) <> 0) and
         (PStrLen(PtrUInt(Values^) - _STRLEN)^ = ValueLen) and
         CompareMemFixed(pointer(PtrInt(Values^)), pointer(Value), ValueLen) then
        exit
      else
        inc(Values)
  else
    for result := 0 to ValuesCount do
      if (PtrUInt(Values^) <> 0) and // StrIComp() won't change length
         (PStrLen(PtrUInt(Values^) - _STRLEN)^ = ValueLen) and
         (StrIComp(pointer(Values^), pointer(Value)) = 0) then
        exit
      else
        inc(Values);
  result := -1;
end;

function FindPropName(Values: PRawUTF8; const Value: RawUTF8; ValuesCount: integer): integer;
var
  ValueLen: TStrLen;
begin
  dec(ValuesCount);
  ValueLen := length(Value);
  if ValueLen = 0 then
    for result := 0 to ValuesCount do
      if Values^ = '' then
        exit
      else
        inc(Values)
  else
    for result := 0 to ValuesCount do
      if (PtrUInt(Values^) <> 0) and
         (PStrLen(PtrUInt(Values^) - _STRLEN)^ = ValueLen) and
         IdemPropNameUSameLen(pointer(Values^), pointer(Value), ValueLen) then
        exit
      else
        inc(Values);
  result := -1;
end;

function FindRawUTF8(const Values: TRawUTF8DynArray; const Value: RawUTF8;
  CaseSensitive: boolean): integer;
begin
  result := FindRawUTF8(pointer(Values), Value, length(Values), CaseSensitive);
end;

function FindRawUTF8(const Values: array of RawUTF8; const Value: RawUTF8;
  CaseSensitive: boolean): integer;
begin
  result := high(Values);
  if result >= 0 then
    result := FindRawUTF8(@Values[0], Value, result + 1, CaseSensitive);
end;

function FindPropName(const Names: array of RawUTF8; const Name: RawUTF8): integer;
begin
  result := high(Names);
  if result >= 0 then
    result := FindPropName(@Names[0], Name, result + 1);
end;

function AddRawUTF8(var Values: TRawUTF8DynArray; const Value: RawUTF8;
  NoDuplicates, CaseSensitive: boolean): boolean;
var
  i: integer;
begin
  if NoDuplicates then
  begin
    i := FindRawUTF8(Values, Value, CaseSensitive);
    if i >= 0 then
    begin
      result := false;
      exit;
    end;
  end;
  i := length(Values);
  SetLength(Values, i + 1);
  Values[i] := Value;
  result := true;
end;

procedure AddRawUTF8(var Values: TRawUTF8DynArray; var ValuesCount: integer;
  const Value: RawUTF8);
var
  capacity: integer;
begin
  capacity := Length(Values);
  if ValuesCount = capacity then
    SetLength(Values, NextGrow(capacity));
  Values[ValuesCount] := Value;
  inc(ValuesCount);
end;

function RawUTF8DynArrayEquals(const A, B: TRawUTF8DynArray): boolean;
var
  n, i: integer;
begin
  result := false;
  n := length(A);
  if n <> length(B) then
    exit;
  for i := 0 to n - 1 do
    if A[i] <> B[i] then
      exit;
  result := true;
end;

function RawUTF8DynArrayEquals(const A, B: TRawUTF8DynArray; Count: integer): boolean;
var
  i: integer;
begin
  result := false;
  for i := 0 to Count - 1 do
    if A[i] <> B[i] then
      exit;
  result := true;
end;

procedure StringDynArrayToRawUTF8DynArray(const Source: TStringDynArray;
  var Result: TRawUTF8DynArray);
var
  i: Integer;
begin
  Finalize(Result);
  SetLength(Result, length(Source));
  for i := 0 to length(Source) - 1 do
    StringToUTF8(Source[i], Result[i]);
end;

procedure StringListToRawUTF8DynArray(Source: TStringList; var Result: TRawUTF8DynArray);
var
  i: Integer;
begin
  Finalize(Result);
  SetLength(Result, Source.Count);
  for i := 0 to Source.Count - 1 do
    StringToUTF8(Source[i], Result[i]);
end;

function FastLocatePUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char): PtrInt;
begin
  Result := FastLocatePUTF8CharSorted(P, R, Value, TUTF8Compare(@StrComp));
end;

function FastLocatePUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt;
  Value: PUTF8Char; Compare: TUTF8Compare): PtrInt;
var
  L, i, cmp: PtrInt;
begin // fast O(log(n)) binary search
  if not Assigned(Compare) or (R < 0) then
    Result := 0
  else if Compare(P^[R], Value) < 0 then // quick return if already sorted
    Result := R + 1
  else
  begin
    L := 0;
    Result := -1; // return -1 if found
    repeat
      i := (L + R) shr 1;
      cmp := Compare(P^[i], Value);
      if cmp = 0 then
        exit;
      if cmp < 0 then
        L := i + 1
      else
        R := i - 1;
    until (L > R);
    while (i >= 0) and (Compare(P^[i], Value) >= 0) do
      dec(i);
    Result := i + 1; // return the index where to insert
  end;
end;

function FastFindPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt;
  Value: PUTF8Char; Compare: TUTF8Compare): PtrInt;
var
  L, cmp: PtrInt;
begin // fast O(log(n)) binary search
  L := 0;
  if Assigned(Compare) and (R >= 0) then
    repeat
      Result := (L + R) shr 1;
      cmp := Compare(P^[Result], Value);
      if cmp = 0 then
        exit;
      if cmp < 0 then
      begin
        L := Result + 1;
        if L <= R then
          continue;
        break;
      end;
      R := Result - 1;
      if L <= R then
        continue;
      break;
    until false;
  Result := -1;
end;

{$ifdef CPUX64}

function FastFindPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char): PtrInt;
{$ifdef FPC} assembler; nostackframe; asm {$else} asm .noframe {$endif}
        {$ifdef win64}  // P=rcx/rdi R=rdx/rsi Value=r8/rdx
        push    rdi
        mov     rdi, P  // P=rdi
        {$endif}
        push    r12
        push    r13
        xor     r9, r9  // L=r9
        test    R, R
        jl      @err
        test    Value, Value
        jz      @void
        mov     cl, byte ptr[Value]  // to check first char (likely diverse)
@s:     lea     rax, qword ptr[r9 + R]
        shr     rax, 1
        lea     r12, qword ptr[rax - 1]  // branchless main loop
        lea     r13, qword ptr[rax + 1]
        mov     r10, qword ptr[rdi + rax * 8]
        test    r10, r10
        jz      @lt
        cmp     cl, byte ptr[r10]
        je      @eq
        cmovc   R, r12
        cmovnc  r9, r13
@nxt:   cmp     r9, R
        jle     @s
@err:   or      rax, -1
@found: pop     r13
        pop     r12
        {$ifdef win64}
        pop     rdi
        {$endif}
        ret
@lt:    mov     r9, r13 // very unlikely P[rax]=nil
        jmp     @nxt
@eq:    mov     r11, Value // first char equal -> check others
@sub:   mov     cl, byte ptr[r10]
        inc     r10
        inc     r11
        test    cl, cl
        jz      @found
        mov     cl, byte ptr[r11]
        cmp     cl, byte ptr[r10]
        je      @sub
        mov     cl, byte ptr[Value]  // reset first char
        cmovc   R, r12
        cmovnc  r9, r13
        cmp     r9, R
        jle     @s
        jmp     @err
@void:  or      rax, -1
        cmp     qword ptr[P], 0
        cmove   rax, Value
        jmp     @found
end;

{$else}

function FastFindPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt; Value: PUTF8Char): PtrInt;
var
  L: PtrInt;
  c: byte;
  piv, val: PByte;
begin // fast O(log(n)) binary search using inlined StrCompFast()
  if R >= 0 then
    if Value <> nil then
    begin
      L := 0;
      repeat
        Result := (L + R) shr 1;
        piv := pointer(P^[Result]);
        if piv <> nil then
        begin
          val := pointer(Value);
          c := piv^;
          if c = val^ then
            repeat
              if c = 0 then
                exit;  // StrComp(P^[result],Value)=0
              inc(piv);
              inc(val);
              c := piv^;
            until c <> val^;
          if c > val^ then
          begin
            R := Result - 1;  // StrComp(P^[result],Value)>0
            if L <= R then
              continue;
            break;
          end;
        end;
        L := Result + 1;  // StrComp(P^[result],Value)<0
        if L <= R then
          continue;
        break;
      until false;
    end
    else if P^[0] = nil then
    begin // '' should be in lowest P[] slot
      Result := 0;
      exit;
    end;
  Result := -1;
end;

{$endif CPUX64}

function FastFindUpperPUTF8CharSorted(P: PPUTF8CharArray; R: PtrInt;
  Value: PUTF8Char; ValueLen: PtrInt): PtrInt;
var
  tmp: array[byte] of AnsiChar;
begin
  UpperCopy255Buf(@tmp, Value, ValueLen);
  Result := FastFindPUTF8CharSorted(P, R, @tmp);
end;

function FastFindIndexedPUTF8Char(P: PPUTF8CharArray; R: PtrInt;
  var SortedIndexes: TCardinalDynArray; Value: PUTF8Char; ItemComp: TUTF8Compare): PtrInt;
var
  L, cmp: PtrInt;
begin // fast O(log(n)) binary search
  L := 0;
  if 0 <= R then
    repeat
      Result := (L + R) shr 1;
      cmp := ItemComp(P^[SortedIndexes[Result]], Value);
      if cmp = 0 then
      begin
        Result := SortedIndexes[Result];
        exit;
      end;
      if cmp < 0 then
      begin
        L := Result + 1;
        if L <= R then
          continue;
        break;
      end;
      R := Result - 1;
      if L <= R then
        continue;
      break;
    until false;
  Result := -1;
end;

function AddSortedRawUTF8(var Values: TRawUTF8DynArray; var ValuesCount: integer;
  const Value: RawUTF8; CoValues: PIntegerDynArray; ForcedIndex: PtrInt;
  Compare: TUTF8Compare): PtrInt;
var
  n: PtrInt;
begin
  if ForcedIndex >= 0 then
    Result := ForcedIndex
  else
  begin
    if not Assigned(Compare) then
      Compare := @StrComp;
    Result := FastLocatePUTF8CharSorted(pointer(Values), ValuesCount - 1,
      pointer(Value), Compare);
    if Result < 0 then
      exit; // Value exists -> fails
  end;
  n := Length(Values);
  if ValuesCount = n then
  begin
    n := NextGrow(n);
    SetLength(Values, n);
    if CoValues <> nil then
      SetLength(CoValues^, n);
  end;
  n := ValuesCount;
  if Result < n then
  begin
    n := (n - Result) * SizeOf(pointer);
    MoveFast(Pointer(Values[Result]), Pointer(Values[Result + 1]), n);
    PtrInt(Values[Result]) := 0; // avoid GPF
    if CoValues <> nil then
    begin
      {$ifdef CPU64} n := n shr 1; {$endif} // 64-bit pointer to 32-bit integer
      MoveFast(CoValues^[Result], CoValues^[Result + 1], n);
    end;
  end
  else
    Result := n;
  Values[Result] := Value;
  inc(ValuesCount);
end;

type
  /// used internaly for faster quick sort
  TQuickSortRawUTF8 = object
    Values: PPointerArray;
    Compare: TUTF8Compare;
    CoValues: PIntegerArray;
    pivot: pointer;
    procedure Sort(L, R: PtrInt);
  end;

procedure TQuickSortRawUTF8.Sort(L, R: PtrInt);
var
  I, J, P: PtrInt;
  Tmp: Pointer;
  TmpInt: integer;
begin
  if L < R then
    repeat
      I := L;
      J := R;
      P := (L + R) shr 1;
      repeat
        pivot := Values^[P];
        while Compare(Values^[I], pivot) < 0 do
          Inc(I);
        while Compare(Values^[J], pivot) > 0 do
          Dec(J);
        if I <= J then
        begin
          Tmp := Values^[J];
          Values^[J] := Values^[I];
          Values^[I] := Tmp;
          if CoValues <> nil then
          begin
            TmpInt := CoValues^[J];
            CoValues^[J] := CoValues^[I];
            CoValues^[I] := TmpInt;
          end;
          if P = I then
            P := J
          else if P = J then
            P := I;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if J - L < R - I then
      begin // use recursion only for smaller range
        if L < J then
          Sort(L, J);
        L := I;
      end
      else
      begin
        if I < R then
          Sort(I, R);
        R := J;
      end;
    until L >= R;
end;

procedure QuickSortRawUTF8(var Values: TRawUTF8DynArray; ValuesCount: integer;
  CoValues: PIntegerDynArray; Compare: TUTF8Compare);
var
  QS: TQuickSortRawUTF8;
begin
  QS.Values := pointer(Values);
  if Assigned(Compare) then
    QS.Compare := Compare
  else
    QS.Compare := @StrComp;
  if CoValues = nil then
    QS.CoValues := nil
  else
    QS.CoValues := pointer(CoValues^);
  QS.Sort(0, ValuesCount - 1);
end;

function DeleteRawUTF8(var Values: TRawUTF8DynArray; Index: integer): boolean;
var
  n: integer;
begin
  n := length(Values);
  if cardinal(Index) >= cardinal(n) then
    Result := false
  else
  begin
    dec(n);
    if PRefCnt(PtrUInt(Values) - _DAREFCNT)^ > 1 then
      Values := copy(Values); // make unique
    Values[Index] := ''; // avoid GPF
    if n > Index then
    begin
      MoveFast(pointer(Values[Index + 1]), pointer(Values[Index]),
        (n - Index) * SizeOf(pointer));
      PtrUInt(Values[n]) := 0; // avoid GPF
    end;
    SetLength(Values, n);
    Result := true;
  end;
end;

function DeleteRawUTF8(var Values: TRawUTF8DynArray; var ValuesCount: integer;
  Index: integer; CoValues: PIntegerDynArray): boolean;
var
  n: integer;
begin
  n := ValuesCount;
  if cardinal(Index) >= cardinal(n) then
    Result := false
  else
  begin
    dec(n);
    ValuesCount := n;
    if PRefCnt(PtrUInt(Values) - _DAREFCNT)^ > 1 then
      Values := copy(Values); // make unique
    Values[Index] := ''; // avoid GPF
    dec(n, Index);
    if n > 0 then
    begin
      if CoValues <> nil then
        MoveFast(CoValues^[Index + 1], CoValues^[Index], n * SizeOf(Integer));
      MoveFast(pointer(Values[Index + 1]), pointer(Values[Index]), n * SizeOf(pointer));
      PtrUInt(Values[ValuesCount]) := 0; // avoid GPF
    end;
    Result := true;
  end;
end;


{ ************ Numbers (integers or floats) to Text Conversion }

procedure Int32ToUTF8(Value: PtrInt; var result: RawUTF8);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  if PtrUInt(Value) <= high(SmallUInt32UTF8) then
    result := SmallUInt32UTF8[Value]
  else
  begin
    P := StrInt32(@tmp[23], Value);
    FastSetString(result, P, @tmp[23] - P);
  end;
end;

function Int32ToUtf8(Value: PtrInt): RawUTF8;
begin
  Int32ToUTF8(Value, result);
end;

procedure Int64ToUtf8(Value: Int64; var result: RawUTF8);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  {$ifdef CPU64}
  if PtrUInt(Value) <= high(SmallUInt32UTF8) then
  {$else} // Int64Rec gives compiler internal error C4963
  if (PCardinalArray(@Value)^[0] <= high(SmallUInt32UTF8)) and
     (PCardinalArray(@Value)^[1] = 0) then
  {$endif CPU64}
    result := SmallUInt32UTF8[Value]
  else
  begin
    {$ifdef CPU64}
    P := StrInt32(@tmp[23], Value);
    {$else}
    P := StrInt64(@tmp[23], Value);
    {$endif}
    FastSetString(result, P, @tmp[23] - P);
  end;
end;

procedure UInt64ToUtf8(Value: QWord; var result: RawUTF8);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  {$ifdef CPU64}
  if Value <= high(SmallUInt32UTF8) then
  {$else} // Int64Rec gives compiler internal error C4963
  if (PCardinalArray(@Value)^[0] <= high(SmallUInt32UTF8)) and
     (PCardinalArray(@Value)^[1] = 0) then
  {$endif CPU64}
    result := SmallUInt32UTF8[Value]
  else
  begin
    {$ifdef CPU64}
    P := StrUInt32(@tmp[23], Value);
    {$else}
    P := StrUInt64(@tmp[23], Value);
    {$endif}
    FastSetString(result, P, @tmp[23] - P);
  end;
end;

function Int64ToUtf8(Value: Int64): RawUTF8; // faster than SysUtils.IntToStr
begin
  Int64ToUtf8(Value, result);
end;

{$ifndef CPU64} // already implemented by ToUTF8(Value: PtrInt) below
function ToUTF8(Value: Int64): RawUTF8;
begin
  Int64ToUTF8(Value, result);
end;
{$endif CPU64}

function ToUTF8(Value: PtrInt): RawUTF8;
begin
  Int32ToUTF8(Value, result);
end;

procedure UInt32ToUtf8(Value: PtrUInt; var result: RawUTF8);
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  if Value <= high(SmallUInt32UTF8) then
    result := SmallUInt32UTF8[Value]
  else
  begin
    P := StrUInt32(@tmp[23], Value);
    FastSetString(result, P, @tmp[23] - P);
  end;
end;

function UInt32ToUtf8(Value: PtrUInt): RawUTF8;
begin
  UInt32ToUTF8(Value, result);
end;

function StrCurr64(P: PAnsiChar; const Value: Int64): PAnsiChar;
var
  c: QWord;
  d: cardinal;
begin
  if Value = 0 then
  begin
    result := P - 1;
    result^ := '0';
    exit;
  end;
  if Value < 0 then
    c := -Value
  else
    c := Value;
  if c < 10000 then
  begin
    result := P - 6; // only decimals -> append '0.xxxx'
    PWord(result)^ := ord('0') + ord('.') shl 8;
    YearToPChar(c, PUTF8Char(P) - 4);
  end
  else
  begin
    result := StrUInt64(P - 1, c);
    d := PCardinal(P - 5)^; // in two explit steps for CPUARM (alf)
    PCardinal(P - 4)^ := d;
    P[-5] := '.'; // insert '.' just before last 4 decimals
  end;
  if Value < 0 then
  begin
    dec(result);
    result^ := '-';
  end;
end;

procedure Curr64ToStr(const Value: Int64; var result: RawUTF8);
var
  tmp: array[0..31] of AnsiChar;
  P: PAnsiChar;
  Decim, L: Cardinal;
begin
  if Value = 0 then
    result := SmallUInt32UTF8[0]
  else
  begin
    P := StrCurr64(@tmp[31], Value);
    L := @tmp[31] - P;
    if L > 4 then
    begin
      Decim := PCardinal(P + L - SizeOf(cardinal))^; // 4 last digits = 4 decimals
      if Decim = ord('0') + ord('0') shl 8 + ord('0') shl 16 + ord('0') shl 24 then
        dec(L, 5)
      else // no decimal
      if Decim and $ffff0000 = ord('0') shl 16 + ord('0') shl 24 then
        dec(L, 2); // 2 decimals
    end;
    FastSetString(result, P, L);
  end;
end;

function Curr64ToStr(const Value: Int64): RawUTF8;
begin
  Curr64ToStr(Value, result);
end;

function CurrencyToStr(const Value: TSynCurrency): RawUTF8;
begin
  result := Curr64ToStr(PInt64(@Value)^);
end;

function Curr64ToPChar(const Value: Int64; Dest: PUTF8Char): PtrInt;
var
  tmp: array[0..31] of AnsiChar;
  P: PAnsiChar;
  Decim: Cardinal;
begin
  P := StrCurr64(@tmp[31], Value);
  result := @tmp[31] - P;
  if result > 4 then
  begin
    Decim := PCardinal(P + result - SizeOf(cardinal))^; // 4 last digits = 4 decimals
    if Decim = ord('0') + ord('0') shl 8 + ord('0') shl 16 + ord('0') shl 24 then
      dec(result, 5)
    else // no decimal
    if Decim and $ffff0000 = ord('0') shl 16 + ord('0') shl 24 then
      dec(result, 2); // 2 decimals
  end;
  MoveSmall(P, Dest, result);
end;

function StrToCurr64(P: PUTF8Char; NoDecimal: PBoolean): Int64;
var
  c: cardinal;
  minus: boolean;
  Dec: cardinal;
begin
  result := 0;
  if P = nil then
    exit;
  while (P^ <= ' ') and (P^ <> #0) do
    inc(P);
  if P^ = '-' then
  begin
    minus := true;
    repeat
      inc(P)
    until P^ <> ' ';
  end
  else
  begin
    minus := false;
    if P^ = '+' then
      repeat
        inc(P)
      until P^ <> ' ';
  end;
  if P^ = '.' then
  begin // '.5' -> 500
    Dec := 2;
    inc(P);
  end
  else
    Dec := 0;
  c := byte(P^) - 48;
  if c > 9 then
    exit;
  PCardinal(@result)^ := c;
  inc(P);
  repeat
    if P^ <> '.' then
    begin
      c := byte(P^) - 48;
      if c > 9 then
        break;
      {$ifdef CPU32DELPHI}
      result := result shl 3 + result + result;
      {$else}
      result := result * 10;
      {$endif}
      inc(result, c);
      inc(P);
      if Dec <> 0 then
      begin
        inc(Dec);
        if Dec < 5 then
          continue
        else
          break;
      end;
    end
    else
    begin
      inc(Dec);
      inc(P);
    end;
  until false;
  if NoDecimal <> nil then
    if Dec = 0 then
    begin
      NoDecimal^ := true;
      if minus then
        result := -result;
      exit;
    end
    else
      NoDecimal^ := false;
  if Dec <> 5 then // Dec=5 most of the time
    case Dec of
      0, 1:
        result := result * 10000;
      {$ifdef CPU32DELPHI}
      2:
        result := result shl 10 - result shl 4 - result shl 3;
      3:
        result := result shl 6 + result shl 5 + result shl 2;
      4:
        result := result shl 3 + result + result;
      {$else}
      2:
        result := result * 1000;
      3:
        result := result * 100;
      4:
        result := result * 10;
      {$endif CPU32DELPHI}
    end;
  if minus then
    result := -result;
end;

function StrToCurrency(P: PUTF8Char): TSynCurrency;
begin
  PInt64(@result)^ := StrToCurr64(P, nil);
end;

{$ifdef UNICODE}

function IntToString(Value: integer): string;
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  P := StrInt32(@tmp[23], Value);
  Ansi7ToString(PWinAnsiChar(P), @tmp[23] - P, result);
end;

function IntToString(Value: cardinal): string;
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  P := StrUInt32(@tmp[23], Value);
  Ansi7ToString(PWinAnsiChar(P), @tmp[23] - P, result);
end;

function IntToString(Value: Int64): string;
var
  tmp: array[0..31] of AnsiChar;
  P: PAnsiChar;
begin
  P := StrInt64(@tmp[31], Value);
  Ansi7ToString(PWinAnsiChar(P), @tmp[31] - P, result);
end;

function DoubleToString(Value: Double): string;
var
  tmp: ShortString;
begin
  if Value = 0 then
    result := '0'
  else
    Ansi7ToString(PWinAnsiChar(@tmp[1]), DoubleToShort(tmp, Value), result);
end;

function Curr64ToString(Value: Int64): string;
var
  tmp: array[0..31] of AnsiChar;
begin
  Ansi7ToString(tmp, Curr64ToPChar(Value, tmp), result);
end;

{$else UNICODE}

function IntToString(Value: integer): string;
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  if cardinal(Value) <= high(SmallUInt32UTF8) then
    result := SmallUInt32UTF8[Value]
  else
  begin
    P := StrInt32(@tmp[23], Value);
    SetString(result, P, @tmp[23] - P);
  end;
end;

function IntToString(Value: cardinal): string;
var
  tmp: array[0..23] of AnsiChar;
  P: PAnsiChar;
begin
  if Value <= high(SmallUInt32UTF8) then
    result := SmallUInt32UTF8[Value]
  else
  begin
    P := StrUInt32(@tmp[23], Value);
    SetString(result, P, @tmp[23] - P);
  end;
end;

function IntToString(Value: Int64): string;
var
  tmp: array[0..31] of AnsiChar;
  P: PAnsiChar;
begin
  if (Value >= 0) and (Value <= high(SmallUInt32UTF8)) then
    result := SmallUInt32UTF8[Value]
  else
  begin
    P := StrInt64(@tmp[31], Value);
    SetString(result, P, @tmp[31] - P);
  end;
end;

function DoubleToString(Value: Double): string;
var
  tmp: ShortString;
begin
  if Value = 0 then
    result := '0'
  else
    SetString(result, PAnsiChar(@tmp[1]), DoubleToShort(tmp, Value));
end;

function Curr64ToString(Value: Int64): string;
begin
  result := Curr64ToStr(Value);
end;

{$endif UNICODE}

{$ifndef EXTENDEDTOSHORT_USESTR}
var // standard FormatSettings (US)
  SettingsUS: TFormatSettings;
{$endif}

// used ExtendedToShortNoExp / DoubleToShortNoExp from str/DoubleToAscii output
function FloatStringNoExp(S: PAnsiChar; Precision: PtrInt): PtrInt;
var
  i, prec: PtrInt;
  c: AnsiChar;
begin
  result := ord(S[0]);
  prec := result; // if no decimal
  if S[1] = '-' then
    dec(prec);
  for i := 2 to result do
  begin // test if scientific format -> return as this
    c := S[i];
    if c = 'E' then // should not appear
      exit
    else if c = '.' then
      if i >= Precision then
      begin // return huge decimal number as is
        result := i - 1;
        exit;
      end
      else
        dec(prec);
  end;
  if (prec >= Precision) and (prec <> result) then
  begin
    dec(result, prec - Precision);
    if S[result + 1] > '5' then
    begin // manual rounding
      prec := result;
      repeat
        c := S[prec];
        if c <> '.' then
          if c = '9' then
          begin
            S[prec] := '0';
            if ((prec = 2) and (S[1] = '-')) or (prec = 1) then
            begin
              i := result;
              inc(S, prec);
              repeat // inlined Move(S[prec],S[prec+1],result);
                S[i] := S[i - 1];
                dec(i);
              until i = 0;
              S^ := '1';
              dec(S, prec);
              break;
            end;
          end
          else if (c >= '0') and (c <= '8') then
          begin
            inc(S[prec]);
            break;
          end
          else
            break;
        dec(prec);
      until prec = 0;
    end; // note: this fixes http://stackoverflow.com/questions/2335162
  end;
  if S[result] = '0' then
    repeat
      dec(result); // trunc any trimming 0
      c := S[result];
      if c <> '.' then
        if c <> '0' then
          break
        else
          continue
      else
      begin
        dec(result);
        if (result = 2) and (S[1] = '-') and (S[2] = '0') then
        begin
          result := 1;
          S[1] := '0'; // '-0.000' -> '0'
        end;
        break; // if decimal are all '0' -> return only integer part
      end;
    until false;
end;

function ExtendedToShortNoExp(var S: ShortString; Value: TSynExtended;
  Precision: integer): integer;
begin
  {$ifdef DOUBLETOSHORT_USEGRISU}
  if Precision = DOUBLE_PRECISION then
    DoubleToAscii(0, DOUBLE_PRECISION, Value, @S)
  else
  {$endif DOUBLETOSHORT_USEGRISU}
    str(Value: 0: Precision, S); // not str(Value:0,S) -> '  0.0E+0000'
  result := FloatStringNoExp(@S, Precision);
  S[0] := AnsiChar(result);
end;

const // range when to switch into scientific notation - minimal 6 digits
  SINGLE_HI = 1E3;
  SINGLE_LO = 1E-3;
  DOUBLE_HI = 1E9;
  DOUBLE_LO = 1E-9;
  {$ifdef TSYNEXTENDED80}
  EXT_HI = 1E12;
  EXT_LO = 1E-12;
  {$endif TSYNEXTENDED80}

{$ifdef EXTENDEDTOSHORT_USESTR}
function ExtendedToShort(var S: ShortString; Value: TSynExtended; Precision: integer): integer;
var
  scientificneeded: boolean;
  valueabs: TSynExtended;
begin
  {$ifdef DOUBLETOSHORT_USEGRISU}
  if Precision = DOUBLE_PRECISION then
  begin
    result := DoubleToShort(S, Value);
    exit;
  end;
  {$endif DOUBLETOSHORT_USEGRISU}
  if Value = 0 then
  begin
    PWord(@S)^ := 1 + ord('0') shl 8;
    result := 1;
    exit;
  end;
  scientificneeded := false;
  valueabs := abs(Value);
  if Precision <= SINGLE_PRECISION then
  begin
    if (valueabs > SINGLE_HI) or (valueabs < SINGLE_LO) then
      scientificneeded := true;
  end
  else
  {$ifdef TSYNEXTENDED80}
  if Precision > DOUBLE_PRECISION then
  begin
    if (valueabs > EXT_HI) or (valueabs < EXT_LO) then
      scientificneeded := true;
  end
  else
  {$endif TSYNEXTENDED80}
  if (valueabs > DOUBLE_HI) or (valueabs < DOUBLE_LO) then
    scientificneeded := true;
  if scientificneeded then
  begin
    str(Value, S);
    if S[1] = ' ' then
    begin
      dec(S[0]);
      MoveSmall(@S[2], @S[1], ord(S[0]));
    end;
    result := ord(S[0]);
  end
  else
  begin
    str(Value: 0: Precision, S); // not str(Value:0,S) -> '  0.0E+0000'
    result := FloatStringNoExp(@S, Precision);
    S[0] := AnsiChar(result);
  end;
end;

{$else not EXTENDEDTOSHORT_USESTR}

function ExtendedToShort(var S: ShortString; Value: TSynExtended; Precision: integer): integer;
{$ifdef UNICODE}
var
  i: PtrInt;
{$endif}
begin
  // use ffGeneral: see https://synopse.info/forum/viewtopic.php?pid=442#p442
  result := FloatToText(PChar(@S[1]), Value, fvExtended, ffGeneral, Precision, 0, SettingsUS);
  {$ifdef UNICODE} // FloatToText(PWideChar) is faster than FloatToText(PAnsiChar)
  for i := 1 to result do
    PByteArray(@S)[i] := PWordArray(PtrInt(@S) - 1)[i];
  {$endif}
  S[0] := AnsiChar(result);
end;

{$endif EXTENDEDTOSHORT_USESTR}

function FloatToShortNan(const s: shortstring): TFloatNan;
begin
  case PInteger(@s)^ and $ffdfdfdf of
    3 + ord('N') shl 8 + ord('A') shl 16 + ord('N') shl 24:
      result := fnNan;
    3 + ord('I') shl 8 + ord('N') shl 16 + ord('F') shl 24,
    4 + ord('+') shl 8 + ord('I') shl 16 + ord('N') shl 24:
      result := fnInf;
    4 + ord('-') shl 8 + ord('I') shl 16 + ord('N') shl 24:
      result := fnNegInf;
  else
    result := fnNumber;
  end;
end;

function FloatToStrNan(const s: RawUTF8): TFloatNan;
begin
  case length(s) of
    3:
      case PInteger(s)^ and $dfdfdf of
        ord('N') + ord('A') shl 8 + ord('N') shl 16:
          result := fnNan;
        ord('I') + ord('N') shl 8 + ord('F') shl 16:
          result := fnInf;
      else
        result := fnNumber;
      end;
    4:
      case PInteger(s)^ and $dfdfdfdf of
        ord('+') + ord('I') shl 8 + ord('N') shl 16 + ord('F') shl 24:
          result := fnInf;
        ord('-') + ord('I') shl 8 + ord('N') shl 16 + ord('F') shl 24:
          result := fnNegInf;
      else
        result := fnNumber;
      end;
  else
    result := fnNumber;
  end;
end;

function ExtendedToStr(Value: TSynExtended; Precision: integer): RawUTF8;
begin
  ExtendedToStr(Value, Precision, result);
end;

procedure ExtendedToStr(Value: TSynExtended; Precision: integer; var result: RawUTF8);
var
  tmp: ShortString;
begin
  if Value = 0 then
    result := SmallUInt32UTF8[0]
  else
    FastSetString(result, @tmp[1], ExtendedToShort(tmp, Value, Precision));
end;

function FloatToJSONNan(const s: ShortString): PShortString;
begin
  case PInteger(@s)^ and $ffdfdfdf of
    3 + ord('N') shl 8 + ord('A') shl 16 + ord('N') shl 24:
      result := @JSON_NAN[fnNan];
    3 + ord('I') shl 8 + ord('N') shl 16 + ord('F') shl 24,
    4 + ord('+') shl 8 + ord('I') shl 16 + ord('N') shl 24:
      result := @JSON_NAN[fnInf];
    4 + ord('-') shl 8 + ord('I') shl 16 + ord('N') shl 24:
      result := @JSON_NAN[fnNegInf];
  else
    result := @s;
  end;
end;

function ExtendedToJSON(var tmp: ShortString; Value: TSynExtended;
  Precision: integer; NoExp: boolean): PShortString;
begin
  if Value = 0 then
    result := @JSON_NAN[fnNumber]
  else
  begin
    if NoExp then
      ExtendedToShortNoExp(tmp, Value, Precision)
    else
      ExtendedToShort(tmp, Value, Precision);
    result := FloatToJSONNan(tmp);
  end;
end;

{$ifdef DOUBLETOSHORT_USEGRISU}

{
    Implement 64-bit floating point (double) to ASCII conversion using the
    GRISU-1 efficient algorithm.

    Original Code in flt_core.inc flt_conv.inc flt_pack.inc from FPC RTL.
    Copyright (C) 2013 by Max Nazhalov
    Licenced with LGPL 2 with the linking exception.
    If you don't agree with these License terms, disable this feature
    by undefining DOUBLETOSHORT_USEGRISU in Synopse.inc

    GRISU Original Algorithm
    Copyright (c) 2009 Florian Loitsch

    We extracted a double-to-ascii only cut-down version of those files,
    and made a huge refactoring to reach the best performance, especially
    tuning the Intel target with some dedicated asm and code rewrite.

  With Delphi 10.3 on Win32: (no benefit)
   100000 FloatToText    in 38.11ms i.e. 2,623,570/s, aver. 0us, 47.5 MB/s
   100000 str            in 43.19ms i.e. 2,315,082/s, aver. 0us, 50.7 MB/s
   100000 DoubleToShort  in 45.50ms i.e. 2,197,367/s, aver. 0us, 43.8 MB/s
   100000 DoubleToAscii  in 42.44ms i.e. 2,356,045/s, aver. 0us, 47.8 MB/s

  With Delphi 10.3 on Win64:
   100000 FloatToText    in 61.83ms i.e. 1,617,233/s, aver. 0us, 29.3 MB/s
   100000 str            in 53.20ms i.e. 1,879,663/s, aver. 0us, 41.2 MB/s
   100000 DoubleToShort  in 18.45ms i.e. 5,417,998/s, aver. 0us, 108 MB/s
   100000 DoubleToAscii  in 18.19ms i.e. 5,496,921/s, aver. 0us, 111.5 MB/s

  With FPC on Win32:
   100000 FloatToText    in 115.62ms i.e.  864,842/s, aver. 1us, 15.6 MB/s
   100000 str            in 57.30ms i.e. 1,745,109/s, aver. 0us, 39.9 MB/s
   100000 DoubleToShort  in 23.88ms i.e. 4,187,078/s, aver. 0us, 83.5 MB/s
   100000 DoubleToAscii  in 23.34ms i.e. 4,284,490/s, aver. 0us, 86.9 MB/s

  With FPC on Win64:
   100000 FloatToText    in 76.92ms i.e. 1,300,052/s, aver. 0us, 23.5 MB/s
   100000 str            in 27.70ms i.e. 3,609,456/s, aver. 0us, 82.6 MB/s
   100000 DoubleToShort  in 14.73ms i.e. 6,787,944/s, aver. 0us, 135.4 MB/s
   100000 DoubleToAscii  in 13.78ms i.e. 7,253,735/s, aver. 0us, 147.2 MB/s

  With FPC on Linux x86_64:
   100000 FloatToText    in 81.48ms i.e. 1,227,249/s, aver. 0us, 22.2 MB/s
   100000 str            in 36.98ms i.e. 2,703,871/s, aver. 0us, 61.8 MB/s
   100000 DoubleToShort  in 13.11ms i.e. 7,626,601/s, aver. 0us, 152.1 MB/s
   100000 DoubleToAscii  in 12.59ms i.e. 7,942,180/s, aver. 0us, 161.2 MB/s

  - Our rewrite is twice faster than original flt_conv.inc from FPC RTL (str)
  - Delphi Win32 has trouble making 64-bit computation - no benefit since it
    has good optimized i87 asm (but slower than our code with FPC/Win32)
  - FPC is more efficient when compiling integer arithmetic; we avoided slow
    division by calling our Div100(), but Delphi Win64 is still far behind
  - Delphi Win64 has very slow FloatToText and str()

}

// Controls printing of NaN-sign.
// Undefine to print NaN sign during float->ASCII conversion.
// IEEE does not interpret the sign of a NaN, so leave it defined.
{$define GRISU1_F2A_NAN_SIGNLESS}

// Controls rounding of generated digits when formatting with narrowed
// width (either fixed or exponential notation).
// Traditionally, FPC and BP7/Delphi use "roundTiesToAway" mode.
// Undefine to use "roundTiesToEven" approach.
{$define GRISU1_F2A_HALF_ROUNDUP}

// This one is a hack against Grusu sub-optimality.
// It may be used only strictly together with GRISU1_F2A_HALF_ROUNDUP.
// It does not violate most general rules due to the fact that it is
// applicable only when formatting with narrowed width, where the fine
// view is more desirable, and the precision is already lost, so it can
// be used in general-purpose applications.
// Refer to its implementation.
{$define GRISU1_F2A_AGRESSIVE_ROUNDUP} // Defining this fixes several tests.

// Undefine to enable SNaN support.
// Note: IEEE [754-2008, page 31] requires (1) to recognize "SNaN" during
// ASCII->float, and (2) to generate the "invalid FP operation" exception
// either when SNaN is printed as "NaN", or "SNaN" is evaluated to QNaN,
// so it would be preferable to undefine these settings,
// but the FPC RTL is not ready for this right now..
{$define GRISU1_F2A_NO_SNAN}

/// If Value=0 would just store '0', whatever frac_digits is supplied.
{$define GRISU1_F2A_ZERONOFRACT}

var
  /// fast lookup table for converting any decimal number from
  // 0 to 99 into their byte digits (0..9) equivalence
  // - used e.g. by DoubleToAscii() implementing Grisu algorithm
  TwoDigitByteLookupW: packed array[0..99] of word;

const
  // TFloatFormatProfile for double
  nDig_mantissa = 17;
  nDig_exp10 = 3;

type
  // "Do-It-Yourself Floating Point" structures
  TDIY_FP = record
    f: qword;
    e: integer;
  end;

  TDIY_FP_Power_of_10 = record
    c: TDIY_FP;
    e10: integer;
  end;
  PDIY_FP_Power_of_10 = ^TDIY_FP_Power_of_10;

const
  ROUNDER = $80000000;

{$ifdef CPUINTEL} // our faster version using 128-bit x86_64 multiplication

procedure d2a_diy_fp_multiply(var x, y: TDIY_FP; normalize: boolean;
  out result: TDIY_FP); {$ifdef HASINLINE} inline; {$endif}
var
  p: THash128Rec;
begin
  mul64x64(x.f, y.f, p); // fast x86_64 / i386 asm
  if (p.c1 and ROUNDER) <>  0 then
    inc(p.h);
  result.f := p.h;
  result.e := PtrInt(x.e) + PtrInt(y.e) + 64;
  if normalize then
    if (PQWordRec(@result.f)^.h and ROUNDER) = 0 then
    begin
      result.f := result.f * 2;
      dec(result.e);
    end;
end;

{$else} // regular Grisu method - optimized for 32-bit CPUs

procedure d2a_diy_fp_multiply(var x, y: TDIY_FP; normalize: boolean; out result: TDIY_FP);
var
  _x: TQWordRec absolute x;
  _y: TQWordRec absolute y;
  r: TQWordRec absolute result;
  ac, bc, ad, bd, t1: TQWordRec;
begin
  ac.v := qword(_x.h) * _y.h;
  bc.v := qword(_x.l) * _y.h;
  ad.v := qword(_x.h) * _y.l;
  bd.v := qword(_x.l) * _y.l;
  t1.v := qword(ROUNDER) + bd.h + bc.l + ad.l;
  result.f := ac.v + ad.h + bc.h + t1.h;
  result.e := x.e + y.e + 64;
  if normalize then
    if (r.h and ROUNDER) = 0 then
    begin
      inc(result.f, result.f);
      dec(result.e);
    end;
end;

{$endif CPUINTEL}

const
  // alpha =-61; gamma = 0
  // full cache: 1E-450 .. 1E+432, step = 1E+18
  // sparse = 1/10
  C_PWR10_DELTA = 18;
  C_PWR10_COUNT = 50;

type
  TDIY_FP_Cached_Power10 = record
    base:         array [ 0 .. 9 ] of TDIY_FP_Power_of_10;
    factor_plus:  array [ 0 .. 1 ] of TDIY_FP_Power_of_10;
    factor_minus: array [ 0 .. 1 ] of TDIY_FP_Power_of_10;
    // extra mantissa correction [ulp; signed]
    corrector:    array [ 0 .. C_PWR10_COUNT - 1 ] of shortint;
  end;

const
  CACHED_POWER10: TDIY_FP_Cached_Power10 = (
    base: (
        ( c: ( f: qword($825ECC24C8737830); e: -362 ); e10:  -90 ),
        ( c: ( f: qword($E2280B6C20DD5232); e: -303 ); e10:  -72 ),
        ( c: ( f: qword($C428D05AA4751E4D); e: -243 ); e10:  -54 ),
        ( c: ( f: qword($AA242499697392D3); e: -183 ); e10:  -36 ),
        ( c: ( f: qword($9392EE8E921D5D07); e: -123 ); e10:  -18 ),
        ( c: ( f: qword($8000000000000000); e:  -63 ); e10:    0 ),
        ( c: ( f: qword($DE0B6B3A76400000); e:   -4 ); e10:   18 ),
        ( c: ( f: qword($C097CE7BC90715B3); e:   56 ); e10:   36 ),
        ( c: ( f: qword($A70C3C40A64E6C52); e:  116 ); e10:   54 ),
        ( c: ( f: qword($90E40FBEEA1D3A4B); e:  176 ); e10:   72 )
    );
    factor_plus: (
        ( c: ( f: qword($F6C69A72A3989F5C); e:   534 ); e10:  180 ),
        ( c: ( f: qword($EDE24AE798EC8284); e:  1132 ); e10:  360 )
    );
    factor_minus: (
        ( c: ( f: qword($84C8D4DFD2C63F3B); e:  -661 ); e10: -180 ),
        ( c: ( f: qword($89BF722840327F82); e: -1259 ); e10: -360 )
    );
    corrector: (
        0,  0,  0,  0,  1,  0,  0,  0,  1, -1,
        0,  1,  1,  1, -1,  0,  0,  1,  0, -1,
        0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
       -1,  0,  0, -1,  0,  0,  0,  0,  0, -1,
        0,  0,  0,  0,  1,  0,  0,  0, -1,  0
    ));
  CACHED_POWER10_MIN10 = -90 -360;
  // = ref.base[low(ref.base)].e10 + ref.factor_minus[high(ref.factor_minus)].e10

// return normalized correctly rounded approximation of the power of 10
// scaling factor, intended to shift a binary exponent of the original number
// into selected [ alpha .. gamma ] range
procedure d2a_diy_fp_cached_power10(exp10: integer; out factor: TDIY_FP_Power_of_10);
var
  i, xmul: integer;
  A, B: PDIY_FP_Power_of_10;
  cx: PtrInt;
  ref: ^TDIY_FP_Cached_Power10;
begin
  ref := @CACHED_POWER10; // much better code generation on PIC/x86_64
  // find non-sparse index
  if exp10 <= CACHED_POWER10_MIN10 then
    i := 0
  else
  begin
    i := (exp10 - CACHED_POWER10_MIN10) div C_PWR10_DELTA;
    if i * C_PWR10_DELTA + CACHED_POWER10_MIN10 <> exp10 then
      inc(i); // round-up
    if i > C_PWR10_COUNT - 1 then
      i := C_PWR10_COUNT - 1;
  end;
  // generate result
  xmul := i div length(ref.base);
  A := @ref.base[i - (xmul * length(ref.base))]; // fast mod
  dec(xmul, length(ref.factor_minus));
  if xmul = 0 then
  begin
    // base
    factor := A^;
    exit;
  end;
  // surrogate
  if xmul > 0 then
  begin
    dec(xmul);
    B := @ref.factor_plus[xmul];
  end
  else
  begin
    xmul := -(xmul + 1);
    B := @ref.factor_minus[xmul];
  end;
  factor.e10 := A.e10 + B.e10;
  if A.e10 <> 0 then
  begin
    d2a_diy_fp_multiply(A.c, B.c, true, factor.c);
    // adjust mantissa
    cx := ref.corrector[i];
    if cx <> 0 then
      inc(int64(factor.c.f), int64(cx));
  end
  else
    // exact
    factor.c := B^.c;
end;

procedure d2a_unpack_float(const f: double; out minus: boolean; out result: TDIY_FP);
  {$ifdef HASINLINE} inline;{$endif}
type
  TSplitFloat = packed record
    case byte of
      0: (f: double);
      1: (b: array[0..7] of byte);
      2: (w: array[0..3] of word);
      3: (d: array[0..1] of cardinal);
      4: (l: qword);
  end;
var
  doublebits: TSplitFloat;
begin
{$ifdef FPC_DOUBLE_HILO_SWAPPED}
  // high and low cardinal are swapped when using the arm fpa
  doublebits.d[0] := TSplitFloat(f).d[1];
  doublebits.d[1] := TSplitFloat(f).d[0];
{$else not FPC_DOUBLE_HILO_SWAPPED}
  doublebits.f := f;
{$endif FPC_DOUBLE_HILO_SWAPPED}
{$ifdef endian_big}
  minus := (doublebits.b[0] and $80 <> 0);
  result.e := (doublebits.w[0] shr 4) and $7FF;
{$else endian_little}
  minus := (doublebits.b[7] and $80 <> 0);
  result.e := (doublebits.w[3] shr 4) and $7FF;
{$endif endian}
  result.f := doublebits.l and $000FFFFFFFFFFFFF;
end;

const
  C_FRAC2_BITS = 52;
  C_EXP2_BIAS = 1023;
  C_DIY_FP_Q = 64;
  C_GRISU_ALPHA = -61;
  C_GRISU_GAMMA = 0;

  C_EXP2_SPECIAL = C_EXP2_BIAS * 2 + 1;
  C_MANT2_INTEGER = qword(1) shl C_FRAC2_BITS;

type
  TAsciiDigits = array[0..39] of byte;
  PAsciiDigits = ^TAsciiDigits;

// convert unsigned integers into decimal digits

{$ifdef FPC_64} // leverage efficient FPC 64-bit division as mul reciprocal

function d2a_gen_digits_64(buf: PAsciiDigits; x: qword): PtrInt;
var
  tab: PWordArray;
  P: PAnsiChar;
  c100: qword;
begin
  tab := @TwoDigitByteLookupW; // 0..99 value -> two byte digits (0..9)
  P := PAnsiChar(@buf[24]); // append backwards
  repeat
    if x >= 100 then
    begin
      dec(P, 2);
      c100 := x div 100;
      dec(x, c100 * 100);
      PWord(P)^ := tab[x]; // 2 digits per loop
      if c100 = 0 then
        break;
      x := c100;
      continue;
    end;
    if x < 10 then
    begin
      dec(P);
      P^ := AnsiChar(x); // 0..9
      break;
    end;
    dec(P, 2);
    PWord(P)^ := tab[x]; // 10..99
    break;
  until false;
  PQWordArray(buf)[0] := PQWordArray(P)[0]; // faster than MoveSmall(P,buf,result)
  PQWordArray(buf)[1] := PQWordArray(P)[1];
  PQWordArray(buf)[2] := PQWordArray(P)[2];
  result := PAnsiChar(@buf[24]) - P;
end;

{$else not FPC_64} // use three 32-bit groups of digit

function d2a_gen_digits_32(buf: PAsciiDigits; x: dword; pad_9zero: boolean): PtrInt;
const
  digits: array[0..9] of cardinal = (
    0, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000);
var
  n: PtrInt;
  m: cardinal;
  {$ifdef FPC}
  z: cardinal;
  {$else}
  d100: TDiv100Rec;
  {$endif FPC}
  tab: PWordArray;
begin
  // Calculate amount of digits
  if x = 0 then
    n := 0  // emit nothing if padding is not required
  else
  begin
    n := integer((BSRdword(x) + 1) * 1233) shr 12;
    if x >= digits[n] then
      inc(n);
  end;
  if pad_9zero and (n < 9) then
    n := 9;
  result := n;
  if n = 0 then
    exit;
  // Emit digits
  dec(PByte(buf));
  tab := @TwoDigitByteLookupW;
  m := x;
  while (n >= 2) and (m <> 0) do
  begin
    dec(n);
    {$ifdef FPC} // FPC will use fast mul reciprocal
    z := m div 100; // compute two 0..9 digits
    PWord(@buf[n])^ := tab^[m - z * 100];
    m := z;
    {$else}
    Div100(m, d100); // our asm is faster than Delphi div operation
    PWord(@buf[n])^ := tab^[d100.M];
    m := d100.D;
    {$endif FPC}
    dec(n);
  end;
  if n = 0 then
    exit;
  if m <> 0 then
  begin
    if m > 9 then
      m := m mod 10; // compute last 0..9 digit
    buf[n] := m;
    dec(n);
    if n = 0 then
      exit;
  end;
  repeat
    buf[n] := 0; // padding with 0
    dec(n);
  until n = 0;
end;

function d2a_gen_digits_64(buf: PAsciiDigits; const x: qword): PtrInt;
var
  n_digits: PtrInt;
  temp: qword;
  splitl, splitm, splith: cardinal;
begin
  // Split X into 3 unsigned 32-bit integers; lower two should be < 10 digits long
  n_digits := 0;
  if x < 1000000000 then
    splitl := x
  else
  begin
    temp := x div 1000000000;
    splitl := x - temp * 1000000000;
    if temp < 1000000000 then
      splitm := temp
    else
    begin
      splith := temp div 1000000000;
      splitm := cardinal(temp) - splith * 1000000000;
      n_digits := d2a_gen_digits_32(buf, splith, false); // Generate hi digits
    end;
    inc(n_digits, d2a_gen_digits_32(@buf[n_digits], splitm, n_digits <> 0));
  end;
  // Generate digits
  inc(n_digits, d2a_gen_digits_32(@buf[n_digits], splitl, n_digits <> 0));
  result := n_digits;
end;

{$endif FPC_64}

// Performs digit sequence rounding, returns decimal point correction
function d2a_round_digits(var buf: TAsciiDigits; var n_current: integer;
  n_max: PtrInt; half_round_to_even: boolean = true): PtrInt;
var
  n: PtrInt;
  dig_round, dig_sticky: byte;
  {$ifdef GRISU1_F2A_AGRESSIVE_ROUNDUP}
  i: PtrInt;
  {$endif}
begin
  result := 0;
  n := n_current;
  n_current := n_max;
  // Get round digit
  dig_round := buf[n_max];
{$ifdef GRISU1_F2A_AGRESSIVE_ROUNDUP}
  // Detect if rounding-up the second last digit turns the "dig_round"
  // into "5"; also make sure we have at least 1 digit between "dig_round"
  // and the second last.
  if not half_round_to_even then
    if (dig_round = 4) and (n_max < n - 3) then
      if buf[n - 2] >= 8 then // somewhat arbitrary...
      begin
        // check for only "9" are in between
        i := n - 2;
        repeat
          dec(i);
        until (i = n_max) or (buf[i] <> 9);
        if i = n_max then
          // force round-up
          dig_round := 9; // any value ">=5"
      end;
{$endif GRISU1_F2A_AGRESSIVE_ROUNDUP}
  if dig_round < 5 then
    exit;
  // Handle "round half to even" case
  if (dig_round = 5) and half_round_to_even and
     ((n_max = 0) or (buf[n_max - 1] and 1 = 0)) then
  begin
    // even and a half: check if exactly the half
    dig_sticky := 0;
    while (n > n_max + 1) and (dig_sticky = 0) do
    begin
      dec(n);
      dig_sticky := buf[n];
    end;
    if dig_sticky = 0 then
      exit; // exactly a half -> no rounding is required
  end;
  // Round-up
  while n_max > 0 do
  begin
    dec(n_max);
    inc(buf[n_max]);
    if buf[n_max] < 10 then
    begin
      // no more overflow: stop now
      n_current := n_max + 1;
      exit;
    end;
    // continue rounding
  end;
  // Overflow out of the 1st digit, all n_max digits became 0
  buf[0] := 1;
  n_current := 1;
  result := 1;
end;

// format the number in the fixed-point representation
procedure d2a_return_fixed(str: PAnsiChar; minus: boolean; var digits: TAsciiDigits;
  n_digits_have, fixed_dot_pos, frac_digits: integer);
var
  p: PAnsiChar;
  d: PByte;
  cut_digits_at, n_before_dot, n_before_dot_pad0, n_after_dot_pad0,
  n_after_dot, n_tail_pad0: integer;
begin
  // Round digits if necessary
  cut_digits_at := fixed_dot_pos + frac_digits;
  if cut_digits_at < 0 then
    // zero
    n_digits_have := 0
  else if cut_digits_at < n_digits_have then
    // round digits
    inc(fixed_dot_pos, d2a_round_digits(digits, n_digits_have, cut_digits_at
      {$ifdef GRISU1_F2A_HALF_ROUNDUP}, false {$endif} ));
  // Before dot: digits, pad0
  if (fixed_dot_pos <= 0) or (n_digits_have = 0) then
  begin
    n_before_dot := 0;
    n_before_dot_pad0 := 1;
  end
  else if fixed_dot_pos > n_digits_have then
  begin
    n_before_dot := n_digits_have;
    n_before_dot_pad0 := fixed_dot_pos - n_digits_have;
  end
  else
  begin
    n_before_dot := fixed_dot_pos;
    n_before_dot_pad0 := 0;
  end;
  // After dot: pad0, digits, pad0
  if fixed_dot_pos < 0 then
    n_after_dot_pad0 := -fixed_dot_pos
  else
    n_after_dot_pad0 := 0;
  if n_after_dot_pad0 > frac_digits then
    n_after_dot_pad0 := frac_digits;
  n_after_dot := n_digits_have - n_before_dot;
  n_tail_pad0 := frac_digits - n_after_dot - n_after_dot_pad0;
  p := str + 1;
  // Sign
  if minus then
  begin
    p^ := '-';
    inc(p);
  end;
  // Integer significant digits
  d := @digits;
  if n_before_dot > 0 then
    repeat
      p^ := AnsiChar(d^ + ord('0'));
      inc(p);
      inc(d);
      dec(n_before_dot);
    until n_before_dot = 0;
  // Integer 0-padding
  if n_before_dot_pad0 > 0 then
    repeat
      p^ := '0';
      inc(p);
      dec(n_before_dot_pad0);
    until n_before_dot_pad0 = 0;
  // Fractional part
  if frac_digits <> 0 then
  begin
    // Dot
    p^ := '.';
    inc(p);
    // Pre-fraction 0-padding
    if n_after_dot_pad0 > 0 then
      repeat
        p^ := '0';
        inc(p);
        dec(n_after_dot_pad0);
      until n_after_dot_pad0 = 0;
    // Fraction significant digits
    if n_after_dot > 0 then
      repeat
        p^ := AnsiChar(d^ + ord('0'));
        inc(p);
        inc(d);
        dec(n_after_dot);
      until n_after_dot = 0;
    // Tail 0-padding
    if n_tail_pad0 > 0 then
      repeat
        p^ := '0';
        inc(p);
        dec(n_tail_pad0);
      until n_tail_pad0 = 0;
  end;
  // Store length
  str[0] := AnsiChar(p - str - 1);
end;

// formats the number as exponential representation
procedure d2a_return_exponential(str: PAnsiChar; minus: boolean;
  digits: PByte; n_digits_have, n_digits_req, d_exp: PtrInt);
var
  p, exp: PAnsiChar;
begin
  p := str + 1;
  // Sign
  if minus then
  begin
    p^ := '-';
    inc(p);
  end;
  // Integer part
  if n_digits_have > 0 then
  begin
    p^ := AnsiChar(digits^ + ord('0'));
    dec(n_digits_have);
  end
  else
    p^ := '0';
  inc(p);
  // Dot
  if n_digits_req > 1 then
  begin
    p^ := '.';
    inc(p);
  end;
  // Fraction significant digits
  if n_digits_req < n_digits_have then
    n_digits_have := n_digits_req;
  if n_digits_have > 0 then
  begin
    repeat
      inc(digits);
      p^ := AnsiChar(digits^ + ord('0'));
      inc(p);
      dec(n_digits_have);
    until n_digits_have = 0;
    while p[-1] = '0' do
      dec(p); // trim #.###00000 -> #.###
    if p[-1] = '.' then
      dec(p); // #.0 -> #
  end;
  // Exponent designator
  p^ := 'E';
  inc(p);
  // Exponent sign (+ is not stored, as in Delphi)
  if d_exp < 0 then
  begin
    p^ := '-';
    d_exp := -d_exp;
    inc(p);
  end;
  // Exponent digits
  exp := pointer(SmallUInt32UTF8[d_exp]); // 0..999 range is fine
  PCardinal(p)^ := PCardinal(exp)^;
  inc(p, PStrLen(exp - _STRLEN)^);
  // Store length
  str[0] := AnsiChar(p - str - 1);
end;

/// set one of special results with proper sign
procedure d2a_return_special(str: PAnsiChar; sign: integer; const spec: shortstring);
begin
  // Compute length
  str[0] := spec[0];
  if sign <> 0 then
    inc(str[0]);
  inc(str);
  // Sign
  if sign <> 0 then
  begin
    if sign > 0 then
      str^ := '+'
    else
      str^ := '-';
    inc(str);
  end;
  // Special text (3 chars)
  PCardinal(str)^ := PCardinal(@spec[1])^;
end;


// Calculates the exp10 of a factor required to bring the binary exponent
// of the original number into selected [ alpha .. gamma ] range:
// result := ceiling[ ( alpha - e ) * log10(2) ]
function d2a_k_comp(e, alpha{, gamma}: integer): integer;
var
  dexp: double;
const
  D_LOG10_2: double = 0.301029995663981195213738894724493027; // log10(2)
var
  x, n: integer;
begin
  x := alpha - e;
  dexp := x * D_LOG10_2;
  // ceil( dexp )
  n := trunc(dexp);
  if x > 0 then
    if dexp <> n then
      inc(n); // round-up
  result := n;
end;

procedure DoubleToAscii(min_width, frac_digits: integer; const v: double; str: PAnsiChar);
var
  w, D: TDIY_FP;
  c_mk: TDIY_FP_Power_of_10;
  n, mk, dot_pos, n_digits_need, n_digits_have: integer;
  n_digits_req, n_digits_sci: integer;
  minus: boolean;
  fl, one_maskl: qword;
  one_e: integer;
  {$ifdef CPU32}
  one_mask, f: cardinal; // run a 2nd loop with 32-bit range
  {$endif CPU32}
  buf: TAsciiDigits;
begin
  // Limit parameters
  if frac_digits > 216 then
    frac_digits := 216; // Delphi compatible
  if min_width <= C_NO_MIN_WIDTH then
    min_width := -1 // no minimal width
  else if min_width < 0 then
    min_width := 0; // minimal width is as short as possible
  // Format profile: select "n_digits_need" (and "n_digits_exp")
  n_digits_req := nDig_mantissa;
  // number of digits to be calculated by Grisu
  n_digits_need := nDig_mantissa;
  if n_digits_req < n_digits_need then
    n_digits_need := n_digits_req;
  // number of mantissa digits to be printed in exponential notation
  if min_width < 0 then
    n_digits_sci := n_digits_req
  else
  begin
    n_digits_sci := min_width -1 {sign} -1 {dot} -1 {E} -1 {E-sign} - nDig_exp10;
    if n_digits_sci < 2 then
      n_digits_sci := 2; // at least 2 digits
    if n_digits_sci > n_digits_req then
      n_digits_sci := n_digits_req; // at most requested by real_type
  end;
  // Float -> DIY_FP
  d2a_unpack_float(v, minus, w);
  // Handle Zero
  if (w.e = 0) and (w.f = 0) then
  begin
    {$ifdef GRISU1_F2A_ZERONOFRACT}
    PWord(str)^ := 1 + ord('0') shl 8; // just return '0'
    {$else}
    if frac_digits >= 0 then
      d2a_return_fixed(str, minus, buf, 0, 1, frac_digits)
    else
      d2a_return_exponential(str, minus, @buf, 0, n_digits_sci, 0);
    {$endif GRISU1_F2A_ZERONOFRACT}
    exit;
  end;
  // Handle specials
  if w.e = C_EXP2_SPECIAL then
  begin
    n := 1 - ord(minus) * 2; // default special sign [-1|+1]
    if w.f = 0 then
      d2a_return_special(str, n, C_STR_INF)
    else
    begin
      // NaN [also pseudo-NaN, pseudo-Inf, non-normal for floatx80]
      {$ifdef GRISU1_F2A_NAN_SIGNLESS}
      n := 0;
      {$endif}
      {$ifndef GRISU1_F2A_NO_SNAN}
      if (w.f and (C_MANT2_INTEGER shr 1)) = 0 then
        return_special(str, n, C_STR_SNAN)
      else
      {$endif GRISU1_F2A_NO_SNAN}
        d2a_return_special(str, n, C_STR_QNAN);
    end;
    exit;
  end;
  // Handle denormals
  if w.e <> 0 then
  begin
    // normal
    w.f := w.f or C_MANT2_INTEGER;
    n := C_DIY_FP_Q - C_FRAC2_BITS - 1;
  end
  else
  begin
    // denormal
    n := 63 - BSRqword(w.f);
    inc(w.e);
  end;
  // Final normalization
  w.f := w.f shl n;
  dec(w.e, C_EXP2_BIAS + n + C_FRAC2_BITS);
  // 1. Find the normalized "c_mk = f_c * 2^e_c" such that
  //    "alpha <= e_c + e_w + q <= gamma"
  // 2. Define "V = D * 10^k": multiply the input number by "c_mk", do not
  //    normalize to land into [ alpha .. gamma ]
  // 3. Generate digits ( n_digits_need + "round" )
  if (C_GRISU_ALPHA <= w.e) and (w.e <= C_GRISU_GAMMA) then
  begin
    // no scaling required
    D := w;
    c_mk.e10 := 0;
  end
  else
  begin
    mk := d2a_k_comp(w.e, C_GRISU_ALPHA{, C_GRISU_GAMMA} );
    d2a_diy_fp_cached_power10(mk, c_mk);
    // Let "D = f_D * 2^e_D := w (*) c_mk"
    if c_mk.e10 = 0 then
      D := w
    else
      d2a_diy_fp_multiply(w, c_mk.c, false, D);
  end;
  // Generate digits: integer part
  n_digits_have := d2a_gen_digits_64(@buf, D.f shr (-D.e));
  dot_pos := n_digits_have;
  // Generate digits: fractional part
  {$ifdef CPU32}
  f := 0; // "sticky" digit
  {$endif CPU32}
  if D.e < 0 then
    repeat
      // MOD by ONE
      one_e := D.e;
      one_maskl := qword(1) shl (-D.e) - 1;
      fl := D.f and one_maskl;
      // 64-bit loop (very efficient on x86_64, slower on i386)
      while {$ifdef CPU32} (one_e < -29) and {$endif}
            (n_digits_have < n_digits_need + 1) and (fl <> 0) do
      begin
        // f := f * 5;
        inc(fl, fl shl 2);
        // one := one / 2
        one_maskl := one_maskl shr 1;
        inc(one_e);
        // DIV by one
        buf[n_digits_have] := fl shr (-one_e);
        // MOD by one
        fl := fl and one_maskl;
        // next
        inc(n_digits_have);
      end;
      {$ifdef CPU32}
      if n_digits_have >= n_digits_need + 1 then
      begin
        // only "sticky" digit remains
        f := ord(fl <> 0);
        break;
      end;
      one_mask := cardinal(one_maskl);
      f := cardinal(fl);
      // 32-bit loop
      while (n_digits_have < n_digits_need + 1) and (f <> 0) do
      begin
        // f := f * 5;
        inc(f, f shl 2);
        // one := one / 2
        one_mask := one_mask shr 1;
        inc(one_e);
        // DIV by one
        buf[n_digits_have] := f shr (-one_e);
        // MOD by one
        f := f and one_mask;
        // next
        inc(n_digits_have);
      end;
      {$endif CPU32}
    until true;
  {$ifdef CPU32}
  // Append "sticky" digit if any
  if (f <> 0) and (n_digits_have >= n_digits_need + 1) then
  begin
    // single "<>0" digit is enough
    n_digits_have := n_digits_need + 2;
    buf[n_digits_need + 1] := 1;
  end;
  {$endif CPU32}
  // Round to n_digits_need using "roundTiesToEven"
  if n_digits_have > n_digits_need then
    inc(dot_pos, d2a_round_digits(buf, n_digits_have, n_digits_need));
  // Generate output
  if frac_digits >= 0 then
  begin
    d2a_return_fixed(str, minus, buf, n_digits_have, dot_pos - c_mk.e10,
      frac_digits);
    exit;
  end;
  if n_digits_have > n_digits_sci then
    inc(dot_pos, d2a_round_digits(buf, n_digits_have, n_digits_sci
      {$ifdef GRISU1_F2A_HALF_ROUNDUP}, false {$endif} ));
  d2a_return_exponential(str, minus, @buf, n_digits_have, n_digits_sci,
    dot_pos - c_mk.e10 - 1);
end;

function DoubleToShort(var S: ShortString; const Value: double): integer;
var
  valueabs: double;
begin
  valueabs := abs(Value);
  if (valueabs > DOUBLE_HI) or (valueabs < DOUBLE_LO) then
  begin
    DoubleToAscii(C_NO_MIN_WIDTH, -1, Value, @S); // = str(Value,S) for scientific notation
    result := ord(S[0]);
  end
  else
    result := DoubleToShortNoExp(S, Value);
end;

function DoubleToShortNoExp(var S: ShortString; const Value: double): integer;
begin
  DoubleToAscii(0, DOUBLE_PRECISION, Value, @S); // = str(Value:0:DOUBLE_PRECISION,S)
  result := FloatStringNoExp(@S, DOUBLE_PRECISION);
  S[0] := AnsiChar(result);
end;

{$else} // use regular Extended version

function DoubleToShort(var S: ShortString; const Value: double): integer;
begin
  result := ExtendedToShort(S, Value, DOUBLE_PRECISION);
end;

function DoubleToShortNoExp(var S: ShortString; const Value: double): integer;
begin
  result := ExtendedToShortNoExp(S, Value, DOUBLE_PRECISION);
end;

{$endif DOUBLETOSHORT_USEGRISU}

function DoubleToJSON(var tmp: ShortString; Value: double; NoExp: boolean): PShortString;
begin
  if Value = 0 then
    result := @JSON_NAN[fnNumber]
  else
  begin
    if NoExp then
      DoubleToShortNoExp(tmp, Value)
    else
      DoubleToShort(tmp, Value);
    result := FloatToJSONNan(tmp);
  end;
end;

function DoubleToStr(Value: Double): RawUTF8;
begin
  DoubleToStr(Value, result);
end;

procedure DoubleToStr(Value: Double; var result: RawUTF8);
var
  tmp: ShortString;
begin
  if Value = 0 then
    result := SmallUInt32UTF8[0]
  else
    FastSetString(result, @tmp[1], DoubleToShort(tmp{%H-}, Value));
end;

function FloatStrCopy(s, d: PUTF8Char): PUTF8Char;
var
  c: AnsiChar;
begin
  while s^=' ' do
    inc(s);
  c := s^;
  if (c='+') or (c='-') then
  begin
    inc(s);
    d^ := c;
    inc(d);
    c := s^;
  end;
  if c='.' then
  begin
    PCardinal(d)^ := ord('0')+ord('.')shl 8; // '.5' -> '0.5'
    inc(d,2);
    inc(s);
    c := s^;
  end;
  if (c >= '0') and (c <= '9') then
    repeat
      inc(s);
      d^ := c;
      inc(d);
      c := s^;
      if ((c >= '0') and (c <= '9')) or (c = '.') then
        continue;
      if (c <> 'e') and (c <> 'E') then
        break;
      inc(s);
      d^ := c; // 1.23e120 or 1.23e-45
      inc(d);
      c := s^;
      if c = '-' then
      begin
        inc(s);
        d^ := c;
        inc(d);
        c := s^;
      end;
      while (c >= '0') and (c <= '9') do
      begin
        inc(s);
        d^ := c;
        inc(d);
        c := s^;
      end;
      break;
    until false;
  result := d;
end;


function Char2ToByte(P: PUTF8Char; out Value: Cardinal;
   ConvertHexToBinTab: PByteArray): Boolean;
var
  B: PtrUInt;
begin
  B := ConvertHexToBinTab[ord(P[0])];
  if B <= 9 then
  begin
    Value := B;
    B := ConvertHexToBinTab[ord(P[1])];
    if B <= 9 then
    begin
      Value := Value * 10 + B;
      result := false;
      exit;
    end;
  end;
  result := true; // error
end;

function Char3ToWord(P: PUTF8Char; out Value: Cardinal;
   ConvertHexToBinTab: PByteArray): Boolean;
var
  B: PtrUInt;
begin
  B := ConvertHexToBinTab[ord(P[0])];
  if B <= 9 then
  begin
    Value := B;
    B := ConvertHexToBinTab[ord(P[1])];
    if B <= 9 then
    begin
      Value := Value * 10 + B;
      B := ConvertHexToBinTab[ord(P[2])];
      if B <= 9 then
      begin
        Value := Value * 10 + B;
        result := false;
        exit;
      end;
    end;
  end;
  result := true; // error
end;

function Char4ToWord(P: PUTF8Char; out Value: Cardinal;
   ConvertHexToBinTab: PByteArray): Boolean;
var
  B: PtrUInt;
begin
  B := ConvertHexToBinTab[ord(P[0])];
  if B <= 9 then
  begin
    Value := B;
    B := ConvertHexToBinTab[ord(P[1])];
    if B <= 9 then
    begin
      Value := Value * 10 + B;
      B := ConvertHexToBinTab[ord(P[2])];
      if B <= 9 then
      begin
        Value := Value * 10 + B;
        B := ConvertHexToBinTab[ord(P[3])];
        if B <= 9 then
        begin
          Value := Value * 10 + B;
          result := false;
          exit;
        end;
      end;
    end;
  end;
  result := true; // error
end;


procedure VariantToUTF8(const V: Variant; var result: RawUTF8; var wasString: boolean);
var
  tmp: TVarData;
  vt: cardinal;
begin
  wasString := false;
  vt := TVarData(V).VType;
  with TVarData(V) do
    case vt of
      varEmpty, varNull:
        result := NULL_STR_VAR;
      varSmallint:
        Int32ToUTF8(VSmallInt, result);
      varShortInt:
        Int32ToUTF8(VShortInt, result);
      varWord:
        UInt32ToUTF8(VWord, result);
      varLongWord:
        UInt32ToUTF8(VLongWord, result);
      varByte:
        result := SmallUInt32UTF8[VByte];
      varBoolean:
        if VBoolean then
          result := SmallUInt32UTF8[1]
        else
          result := SmallUInt32UTF8[0];
      varInteger:
        Int32ToUTF8(VInteger, result);
      varInt64:
        Int64ToUTF8(VInt64, result);
      varWord64:
        UInt64ToUTF8(VInt64, result);
      varSingle:
        ExtendedToStr(VSingle, SINGLE_PRECISION, result);
      varDouble:
        DoubleToStr(VDouble, result);
      varCurrency:
        Curr64ToStr(VInt64, result);
      varDate:
        begin
          wasString := true;
          DateTimeToIso8601TextVar(VDate, 'T', result);
        end;
      varString:
        begin
          wasString := true;
          {$ifdef HASCODEPAGE}
          AnyAnsiToUTF8(RawByteString(VString), result);
          {$else}
          result := RawUTF8(VString);
          {$endif}
        end;
      {$ifdef HASVARUSTRING}
      varUString:
        begin
          wasString := true;
          RawUnicodeToUtf8(VAny, length(UnicodeString(VAny)), result);
        end;
      {$endif}
      varOleStr:
        begin
          wasString := true;
          RawUnicodeToUtf8(VAny, length(WideString(VAny)), result);
        end;
    else
      if SetVariantUnRefSimpleValue(V, tmp{%H-}) then // simple varByRef
        VariantToUTF8(Variant(tmp), result, wasString)
      else if vt = varVariant or varByRef then // complex varByRef
        VariantToUTF8(PVariant(VPointer)^, result, wasString)
      else if vt = varByRef or varString then
      begin
        wasString := true;
        {$ifdef HASCODEPAGE}
        AnyAnsiToUTF8(PRawByteString(VString)^, result);
        {$else}
        result := PRawUTF8(VString)^;
        {$endif}
      end
      else if vt = varByRef or varOleStr then
      begin
        wasString := true;
        RawUnicodeToUtf8(pointer(PWideString(VAny)^), length(PWideString(VAny)^), result);
      end
      else
      {$ifdef HASVARUSTRING}
      if vt = varByRef or varUString then
      begin
        wasString := true;
        RawUnicodeToUtf8(pointer(PUnicodeString(VAny)^), length(PUnicodeString(VAny)^), result);
      end
      else
      {$endif}
        VariantSaveJSON(V, twJSONEscape, result); // will handle also custom types
    end;
end;

function VariantToUTF8(const V: Variant): RawUTF8;
var
  wasString: boolean;
begin
  VariantToUTF8(V, result, wasString);
end;

function ToUTF8(const V: Variant): RawUTF8;
var
  wasString: boolean;
begin
  VariantToUTF8(V, result, wasString);
end;

function VariantToUTF8(const V: Variant; var Text: RawUTF8): boolean;
begin
  VariantToUTF8(V, Text, result);
end;

procedure VariantSaveJSON(const Value: variant; Escape: TTextWriterKind;
  var result: RawUTF8);
var
  temp: TTextWriterStackBuffer;
begin // not very fast, but creates valid JSON
  with DefaultTextWriterSerializer.CreateOwnedStream(temp) do
  try
    AddVariant(Value, Escape); // may encounter TObjectVariant -> WriteObject
    SetText(result);
  finally
    Free;
  end;
end;

function VariantSaveJSON(const Value: variant; Escape: TTextWriterKind): RawUTF8;
begin
  VariantSaveJSON(Value, Escape, result);
end;


function UInt4DigitsToShort(Value: Cardinal): TShort4;
begin
  result[0] := #4;
  if Value > 9999 then
    Value := 9999;
  YearToPChar(Value, @result[1]);
end;

function UInt3DigitsToShort(Value: Cardinal): TShort4;
begin
  if Value > 999 then
    Value := 999;
  YearToPChar(Value, @result[0]);
  result[0] := #3; // override first digit
end;

function UInt2DigitsToShort(Value: byte): TShort4;
begin
  result[0] := #2;
  if Value > 99 then
    Value := 99;
  PWord(@result[1])^ := TwoDigitLookupW[Value];
end;

function UInt2DigitsToShortFast(Value: byte): TShort4;
begin
  result[0] := #2;
  PWord(@result[1])^ := TwoDigitLookupW[Value];
end;


{ ************ Text Formatting functions }

function VarRecAsChar(const V: TVarRec): integer;
begin
  case V.VType of
    vtChar:
      result := ord(V.VChar);
    vtWideChar:
      result := ord(V.VWideChar);
  else
    result := 0;
  end;
end;

function VarRecToInt64(const V: TVarRec; out value: Int64): boolean;
begin
  case V.VType of
    vtInteger:
      value := V.VInteger;
    vtInt64 {$ifdef FPC}, vtQWord{$endif}:
      value := V.VInt64^;
    vtBoolean:
      if V.VBoolean then
        value := 1
      else
        value := 0; // normalize
    vtVariant:
      value := V.VVariant^;
  else
    begin
      result := false;
      exit;
    end;
  end;
  result := true;
end;

function VarRecToDouble(const V: TVarRec; out value: double): boolean;
begin
  case V.VType of
    vtInteger:
      value := V.VInteger;
    vtInt64:
      value := V.VInt64^;
    {$ifdef FPC}
    vtQWord:
      value := V.VQWord^;
    {$endif}
    vtBoolean:
      if V.VBoolean then
        value := 1
      else
        value := 0; // normalize
    vtExtended:
      value := V.VExtended^;
    vtCurrency:
      CurrencyToDouble(PSynCurrency(@V.VCurrency), value);
    vtVariant:
      value := V.VVariant^;
  else
    begin
      result := false;
      exit;
    end;
  end;
  result := true;
end;

function VarRecToTempUTF8(const V: TVarRec; var Res: TTempUTF8): integer;
var
  v64: Int64;
  isString: boolean;
label
  smlu32;
begin
  Res.TempRawUTF8 := nil; // avoid GPF
  case V.VType of
    vtString:
      begin
        Res.Text := @V.VString^[1];
        Res.Len := ord(V.VString^[0]);
        result := Res.Len;
        exit;
      end;
    vtAnsiString:
      begin // expect UTF-8 content
        Res.Text := pointer(V.VAnsiString);
        Res.Len := length(RawUTF8(V.VAnsiString));
        result := Res.Len;
        exit;
      end;
    {$ifdef HASVARUSTRING}
    vtUnicodeString:
      RawUnicodeToUtf8(V.VPWideChar, length(UnicodeString(V.VUnicodeString)), RawUTF8(Res.TempRawUTF8));
    {$endif}
    vtWideString:
      RawUnicodeToUtf8(V.VPWideChar, length(WideString(V.VWideString)), RawUTF8(Res.TempRawUTF8));
    vtPChar:
      begin // expect UTF-8 content
        Res.Text := V.VPointer;
        Res.Len := StrLen(V.VPointer);
        result := Res.Len;
        exit;
      end;
    vtChar:
      begin
        Res.Temp[0] := V.VChar; // V may be on transient stack (alf: FPC)
        Res.Text := @Res.Temp;
        Res.Len := 1;
        result := 1;
        exit;
      end;
    vtPWideChar:
      RawUnicodeToUtf8(V.VPWideChar, StrLenW(V.VPWideChar), RawUTF8(Res.TempRawUTF8));
    vtWideChar:
      RawUnicodeToUtf8(@V.VWideChar, 1, RawUTF8(Res.TempRawUTF8));
    vtBoolean:
      begin
        if V.VBoolean then // normalize
          Res.Text := pointer(SmallUInt32UTF8[1])
        else
          Res.Text := pointer(SmallUInt32UTF8[0]);
        Res.Len := 1;
        result := 1;
        exit;
      end;
    vtInteger:
      begin
        result := V.VInteger;
        if cardinal(result) <= high(SmallUInt32UTF8) then
        begin
smlu32:   Res.Text := pointer(SmallUInt32UTF8[result]);
          Res.Len := PStrLen(Res.Text - _STRLEN)^;
        end
        else
        begin
          Res.Text := PUTF8Char(StrInt32(@Res.Temp[23], result));
          Res.Len := @Res.Temp[23] - Res.Text;
        end;
        result := Res.Len;
        exit;
      end;
    vtInt64:
      if (PCardinalArray(V.VInt64)^[0] <= high(SmallUInt32UTF8)) and
         (PCardinalArray(V.VInt64)^[1] = 0) then
      begin
        result := V.VInt64^;
        goto smlu32;
      end
      else
      begin
        Res.Text := PUTF8Char(StrInt64(@Res.Temp[23], V.VInt64^));
        Res.Len := @Res.Temp[23] - Res.Text;
        result := Res.Len;
        exit;
      end;
    {$ifdef FPC}
    vtQWord:
      if V.VQWord^ <= high(SmallUInt32UTF8) then
      begin
        result := V.VQWord^;
        goto smlu32;
      end
      else
      begin
        Res.Text := PUTF8Char(StrUInt64(@Res.Temp[23], V.VQWord^));
        Res.Len := @Res.Temp[23] - Res.Text;
        result := Res.Len;
        exit;
      end;
    {$endif FPC}
    vtCurrency:
      begin
        Res.Text := @Res.Temp;
        Res.Len := Curr64ToPChar(V.VInt64^, Res.Temp);
        result := Res.Len;
        exit;
      end;
    vtExtended:
      DoubleToStr(V.VExtended^, RawUTF8(Res.TempRawUTF8));
    vtPointer, vtInterface:
      begin
        Res.Text := @Res.Temp;
        Res.Len := SizeOf(pointer) * 2;
        BinToHexDisplayLower(V.VPointer, @Res.Temp, SizeOf(Pointer));
        result := SizeOf(pointer) * 2;
        exit;
      end;
    vtClass:
      begin
        if V.VClass <> nil then
        begin
          Res.Text := PPUTF8Char(PtrInt(PtrUInt(V.VClass)) + vmtClassName)^ + 1;
          Res.Len := ord(Res.Text[-1]);
        end
        else
          Res.Len := 0;
        result := Res.Len;
        exit;
      end;
    vtObject:
      begin
        if V.VObject <> nil then
        begin
          Res.Text := PPUTF8Char(PPtrInt(V.VObject)^ + vmtClassName)^ + 1;
          Res.Len := ord(Res.Text[-1]);
        end
        else
          Res.Len := 0;
        result := Res.Len;
        exit;
      end;
    vtVariant:
      if VariantToInt64(V.VVariant^, v64) then
        if (PCardinalArray(@v64)^[0] <= high(SmallUInt32UTF8)) and
           (PCardinalArray(@v64)^[1] = 0) then
        begin
          result := v64;
          goto smlu32;
        end
        else
        begin
          Res.Text := PUTF8Char(StrInt64(@Res.Temp[23], v64));
          Res.Len := @Res.Temp[23] - Res.Text;
          result := Res.Len;
          exit;
        end
      else
        VariantToUTF8(V.VVariant^, RawUTF8(Res.TempRawUTF8), isString);
  else
    begin
      Res.Len := 0;
      result := 0;
      exit;
    end;
  end;
  Res.Text := Res.TempRawUTF8;
  Res.Len := length(RawUTF8(Res.TempRawUTF8));
  result := Res.Len;
end;

procedure VarRecToUTF8(const V: TVarRec; var result: RawUTF8; wasString: PBoolean);
var
  isString: boolean;
begin
  isString := not (V.VType in [vtBoolean, vtInteger, vtInt64
    {$ifdef FPC}, vtQWord{$endif}, vtCurrency, vtExtended]);
  with V do
    case V.VType of
      vtString:
        FastSetString(result, @VString^[1], ord(VString^[0]));
      vtAnsiString:
        result := RawUTF8(VAnsiString); // expect UTF-8 content
      {$ifdef HASVARUSTRING}
      vtUnicodeString:
        RawUnicodeToUtf8(VUnicodeString, length(UnicodeString(VUnicodeString)), result);
      {$endif}
      vtWideString:
        RawUnicodeToUtf8(VWideString, length(WideString(VWideString)), result);
      vtPChar:
        FastSetString(result, VPChar, StrLen(VPChar));
      vtChar:
        FastSetString(result, PAnsiChar(@VChar), 1);
      vtPWideChar:
        RawUnicodeToUtf8(VPWideChar, StrLenW(VPWideChar), result);
      vtWideChar:
        RawUnicodeToUtf8(@VWideChar, 1, result);
      vtBoolean:
        if VBoolean then // normalize
          result := SmallUInt32UTF8[1]
        else
          result := SmallUInt32UTF8[0];
      vtInteger:
        Int32ToUtf8(VInteger, result);
      vtInt64:
        Int64ToUtf8(VInt64^, result);
      {$ifdef FPC}
      vtQWord:
        UInt64ToUtf8(VQWord^, result);
      {$endif}
      vtCurrency:
        Curr64ToStr(VInt64^, result);
      vtExtended:
        DoubleToStr(VExtended^,result);
      vtPointer:
        PointerToHex(VPointer, result);
      vtClass:
        if VClass <> nil then
          ClassToText(VClass, result)
        else
          result := '';
      vtObject:
        if VObject <> nil then
          ClassToText(PClass(VObject)^, result)
        else
          result := '';
      vtInterface:
      {$ifdef HASINTERFACEASTOBJECT}
        if VInterface <> nil then
          ClassToText((IInterface(VInterface) as TObject).ClassType, result)
        else
          result := '';
      {$else}
        PointerToHex(VInterface,result);
      {$endif}
      vtVariant:
        VariantToUTF8(VVariant^, result, isString);
    else
      begin
        isString := false;
        result := '';
      end;
    end;
  if wasString <> nil then
    wasString^ := isString;
end;

function VarRecToUTF8IsString(const V: TVarRec; var value: RawUTF8): boolean;
begin
  VarRecToUTF8(V, value, @result);
end;

procedure VarRecToInlineValue(const V: TVarRec; var result: RawUTF8);
var
  wasString: boolean;
  tmp: RawUTF8;
begin
  VarRecToUTF8(V, tmp, @wasString);
  if wasString then
    QuotedStr(tmp, '"', result)
  else
    result := tmp;
end;

function FormatUTF8(const Format: RawUTF8; const Args: array of const): RawUTF8;
begin
  FormatUTF8(Format, Args, result);
end;

type
  // only supported token is %, with any const arguments
  TFormatUTF8 = object
    b: PTempUTF8;
    L, argN: integer;
    blocks: array[0..63] of TTempUTF8; // to avoid most heap allocations
    procedure Parse(const Format: RawUTF8; const Args: array of const);
    procedure Write(Dest: PUTF8Char);
    function WriteMax(Dest: PUTF8Char; Max: PtrUInt): PUTF8Char;
  end;

procedure TFormatUTF8.Parse(const Format: RawUTF8; const Args: array of const);
var
  F, FDeb: PUTF8Char;
begin
  if length(Args) * 2 >= high(blocks) then
    raise ESynException.Create('FormatUTF8: too many args (max=32)!');
  L := 0;
  argN := 0;
  b := @blocks;
  F := pointer(Format);
  repeat
    if F^ = #0 then
      break;
    if F^ <> '%' then
    begin
      FDeb := F;
      repeat
        inc(F);
      until (F^ = '%') or (F^ = #0);
      b^.Text := FDeb;
      b^.Len := F - FDeb;
      b^.TempRawUTF8 := nil;
      inc(L, b^.Len);
      inc(b);
      if F^ = #0 then
        break;
    end;
    inc(F); // jump '%'
    if argN <= high(Args) then
    begin
      inc(L, VarRecToTempUTF8(Args[argN], b^));
      if b.Len > 0 then
        inc(b);
      inc(argN);
      if F^ = #0 then
        break;
    end
    else // no more available Args -> add all remaining text
    if F^ = #0 then
      break
    else
    begin
      b^.Len := length(Format) - (F - pointer(Format));
      b^.Text := F;
      b^.TempRawUTF8 := nil;
      inc(L, b^.Len);
      inc(b);
      break;
    end;
  until false;
end;

procedure TFormatUTF8.Write(Dest: PUTF8Char);
var
  d: PTempUTF8;
begin
  d := @blocks;
  repeat
    {$ifdef HASINLINE}
    MoveSmall(d^.Text, Dest, d^.Len);
    {$else}
    MoveFast(d^.Text^, Dest^, d^.Len);
    {$endif}
    inc(Dest, d^.Len);
    if d^.TempRawUTF8 <> nil then
      {$ifdef FPC}
      Finalize(RawUTF8(d^.TempRawUTF8));
      {$else}
      RawUTF8(d^.TempRawUTF8) := '';
      {$endif}
    inc(d);
  until d = b;
end;

function TFormatUTF8.WriteMax(Dest: PUTF8Char; Max: PtrUInt): PUTF8Char;
var
  d: PTempUTF8;
begin
  if Max > 0 then
  begin
    inc(Max, PtrUInt(Dest));
    d := @blocks;
    if Dest <> nil then
      repeat
        if PtrUInt(Dest) + PtrUInt(d^.Len) > Max then
        begin // avoid buffer overflow
          {$ifdef HASINLINE}
          MoveSmall(d^.Text, Dest, Max - PtrUInt(Dest));
          {$else}
          MoveFast(d^.Text^, Dest^, Max - PtrUInt(Dest));
          {$endif}
          repeat
            if d^.TempRawUTF8 <> nil then
              {$ifdef FPC}
              Finalize(RawUTF8(d^.TempRawUTF8));
              {$else}
              RawUTF8(d^.TempRawUTF8) := '';
              {$endif}
            inc(d);
          until d = b; // avoid memory leak
          result := PUTF8Char(Max);
          exit;
        end;
        {$ifdef HASINLINE}
        MoveSmall(d^.Text, Dest, d^.Len);
        {$else}
        MoveFast(d^.Text^, Dest^, d^.Len);
        {$endif}
        inc(Dest, d^.Len);
        if d^.TempRawUTF8 <> nil then
          {$ifdef FPC}
          Finalize(RawUTF8(d^.TempRawUTF8));
          {$else}
          RawUTF8(d^.TempRawUTF8) := '';
          {$endif}
        inc(d);
      until d = b;
  end;
  result := Dest;
end;

procedure FormatUTF8(const Format: RawUTF8; const Args: array of const;
  out result: RawUTF8);
var
  process: TFormatUTF8;
begin
  if (Format = '') or (high(Args) < 0) then // no formatting needed
    result := Format
  else if PWord(Format)^ = ord('%') then    // optimize raw conversion
    VarRecToUTF8(Args[0], result)
  else
  begin
    process.Parse(Format, Args);
    if process.L <> 0 then
    begin
      FastSetString(result, nil, process.L);
      process.Write(pointer(result));
    end;
  end;
end;

procedure FormatShort(const Format: RawUTF8; const Args: array of const;
  var result: shortstring);
var
  process: TFormatUTF8;
begin
  if (Format = '') or (high(Args) < 0) then // no formatting needed
    SetString(result, PAnsiChar(pointer(Format)), length(Format))
  else
  begin
    process.Parse(Format, Args);
    result[0] := AnsiChar(process.WriteMax(@result[1], 255) - @result[1]);
  end;
end;

function FormatBuffer(const Format: RawUTF8; const Args: array of const;
  Dest: pointer; DestLen: PtrInt): PtrInt;
var
  process: TFormatUTF8;
begin
  if (Dest = nil) or (DestLen <= 0) then
  begin
    result := 0;
    exit; // avoid buffer overflow
  end;
  process.Parse(Format, Args);
  result := PtrUInt(process.WriteMax(Dest, DestLen)) - PtrUInt(Dest);
end;

function FormatToShort(const Format: RawUTF8; const Args: array of const): shortstring;
var
  process: TFormatUTF8;
begin
  process.Parse(Format, Args);
  result[0] := AnsiChar(process.WriteMax(@result[1], 255) - @result[1]);
end;

procedure FormatShort16(const Format: RawUTF8; const Args: array of const;
  var result: TShort16);
var
  process: TFormatUTF8;
begin
  if (Format = '') or (high(Args) < 0) then // no formatting needed
    SetString(result, PAnsiChar(pointer(Format)), length(Format))
  else
  begin
    process.Parse(Format, Args);
    result[0] := AnsiChar(process.WriteMax(@result[1], 16) - @result[1]);
  end;
end;

procedure FormatString(const Format: RawUTF8; const Args: array of const;
  out result: string);
var
  process: TFormatUTF8;
  temp: TSynTempBuffer; // will avoid most memory allocations
begin
  if (Format = '') or (high(Args) < 0) then
  begin // no formatting needed
    UTF8DecodeToString(pointer(Format), length(Format), result);
    exit;
  end;
  process.Parse(Format, Args);
  temp.Init(process.L);
  process.Write(temp.buf);
  UTF8DecodeToString(temp.buf, process.L, result);
  temp.Done;
end;

function FormatString(const Format: RawUTF8; const Args: array of const): string;
begin
  FormatString(Format, Args, result);
end;


function StringToConsole(const S: string): RawByteString;
begin
  result := Utf8ToConsole(StringToUTF8(S));
end;

procedure ConsoleWrite(const Fmt: RawUTF8; const Args: array of const;
  Color: TConsoleColor; NoLineFeed: boolean);
var
  tmp: RawUTF8;
begin
  FormatUTF8(Fmt, Args, tmp);
  ConsoleWrite(tmp, Color, NoLineFeed);
end;

{$I-}

procedure ConsoleShowFatalException(E: Exception; WaitForEnterKey: boolean);
begin
  ConsoleWrite(#13#10'Fatal exception ', cclightRed, true);
  ConsoleWrite('%', [E.ClassType], ccWhite, true);
  ConsoleWrite(' raised with message ', ccLightRed, true);
  ConsoleWrite('%', [E.Message], ccLightMagenta);
  TextColor(ccLightGray);
  if WaitForEnterKey then
  begin
    writeln(#13#10'Program will now abort');
    {$ifndef LINUX}
    writeln('Press [Enter] to quit');
    ConsoleWaitForEnterKey;
    {$endif}
  end;
  ioresult;
end;

{$I+}


{ ************ Resource and Time Functions }

procedure KB(bytes: Int64; out result: TShort16; nospace: boolean);
type
  TUnits = (kb, mb, gb, tb, pb, eb, b);
const
  TXT: array[boolean, TUnits] of RawUTF8 = (
    (' KB', ' MB', ' GB', ' TB', ' PB', ' EB', '% B'),
    ('KB', 'MB', 'GB', 'TB', 'PB', 'EB', '%B'));
var
  hi, rem: cardinal;
  u: TUnits;
begin
  if bytes < 1 shl 10 - (1 shl 10) div 10 then
  begin
    FormatShort16(TXT[nospace, b], [integer(bytes)], result);
    exit;
  end;
  if bytes < 1 shl 20 - (1 shl 20) div 10 then
  begin
    u := kb;
    rem := bytes;
    hi := bytes shr 10;
  end
  else if bytes < 1 shl 30 - (1 shl 30) div 10 then
  begin
    u := mb;
    rem := bytes shr 10;
    hi := bytes shr 20;
  end
  else if bytes < Int64(1) shl 40 - (Int64(1) shl 40) div 10 then
  begin
    u := gb;
    rem := bytes shr 20;
    hi := bytes shr 30;
  end
  else if bytes < Int64(1) shl 50 - (Int64(1) shl 50) div 10 then
  begin
    u := tb;
    rem := bytes shr 30;
    hi := bytes shr 40;
  end
  else if bytes < Int64(1) shl 60 - (Int64(1) shl 60) div 10 then
  begin
    u := pb;
    rem := bytes shr 40;
    hi := bytes shr 50;
  end
  else
  begin
    u := eb;
    rem := bytes shr 50;
    hi := bytes shr 60;
  end;
  rem := rem and 1023;
  if rem <> 0 then
    rem := rem div 102;
  if rem = 10 then
  begin
    rem := 0;
    inc(hi); // round up as expected by (most) human beings
  end;
  if rem <> 0 then
    FormatShort16('%.%%', [hi, rem, TXT[nospace, u]], result)
  else
    FormatShort16('%%', [hi, TXT[nospace, u]], result);
end;

function KB(bytes: Int64): TShort16;
begin
  KB(bytes, result, {nospace=}false);
end;

function KBNoSpace(bytes: Int64): TShort16;
begin
  KB(bytes, result, {nospace=}true);
end;

function KB(bytes: Int64; nospace: boolean): TShort16;
begin
  KB(bytes, result, nospace);
end;

function KB(const buffer: RawByteString): TShort16;
begin
  KB(length(buffer), result, {nospace=}false);
end;

procedure KBU(bytes: Int64; var result: RawUTF8);
var
  tmp: TShort16;
begin
  KB(bytes, tmp, {nospace=}false);
  FastSetString(result, @tmp[1], ord(tmp[0]));
end;

procedure K(value: Int64; out result: TShort16);
begin
  KB(Value, result, {nospace=}true);
  if result[0] <> #0 then
    dec(result[0]); // just trim last 'B'
end;

function K(value: Int64): TShort16;
begin
  K(Value, result);
end;

function IntToThousandString(Value: integer; const ThousandSep: TShort4): shortstring;
var
  i, L, Len: cardinal;
begin
  str(Value, result);
  L := length(result);
  Len := L + 1;
  if Value < 0 then
    dec(L, 2)
  else // ignore '-' sign
    dec(L);
  for i := 1 to L div 3 do
    insert(ThousandSep, result, Len - i * 3);
end;

function MicroSecToString(Micro: QWord): TShort16;
begin
  MicroSecToString(Micro, result);
end;

procedure MicroSecToString(Micro: QWord; out result: TShort16);

  procedure TwoDigitToString(value: cardinal; const u: shortstring; var result: TShort16);
  var
    d100: TDiv100Rec;
  begin
    if value < 100 then
      FormatShort16('0.%%', [UInt2DigitsToShortFast(value), u], result)
    else
    begin
      Div100(value, d100{%H-});
      if d100.m = 0 then
        FormatShort16('%%', [d100.d, u], result)
      else
        FormatShort16('%.%%', [d100.d, UInt2DigitsToShortFast(d100.m), u], result);
    end;
  end;

  procedure TimeToString(value: cardinal; const u: shortstring; var result: TShort16);
  var
    d: cardinal;
  begin
    d := value div 60;
    FormatShort16('%%%', [d, u, UInt2DigitsToShortFast(value - (d * 60))], result);
  end;

begin
  if Int64(Micro) <= 0 then
    result := '0us'
  else if Micro < 1000 then
    FormatShort16('%us', [Micro], result)
  else if Micro < 1000000 then
    TwoDigitToString({$ifdef CPU32} PCardinal(@Micro)^ {$else} Micro {$endif}
      div 10, 'ms', result)
  else if Micro < 60000000 then
    TwoDigitToString({$ifdef CPU32} PCardinal(@Micro)^ {$else} Micro {$endif}
      div 10000, 's', result)
  else if Micro < QWord(3600000000) then
    TimeToString({$ifdef CPU32} PCardinal(@Micro)^ {$else} Micro {$endif}
      div 1000000, 'm', result)
  else if Micro < QWord(86400000000 * 2) then
    TimeToString(Micro div 60000000, 'h', result)
  else
    FormatShort16('%d', [Micro div QWord(86400000000)], result)
end;


{ ************ ESynException class }

{ ESynException }

constructor ESynException.CreateUTF8(const Format: RawUTF8; const Args: array of const);
var
  msg: string;
begin
  FormatString(Format, Args, msg);
  inherited Create(msg);
end;

constructor ESynException.CreateLastOSError(const Format: RawUTF8;
  const Args: array of const);
var
  tmp: RawUTF8;
  error: integer;
begin
  error := {$ifdef FPC} GetLastOSError {$else} GetLastError {$endif};
  FormatUTF8(Format, Args, tmp);
  CreateUTF8('OSError % [%] %', [error, SysErrorMessage(error), tmp]);
end;

{$ifndef NOEXCEPTIONINTERCEPT}

function DefaultSynLogExceptionToStr(WR: TBaseWriter;
  const Context: TSynLogExceptionContext): boolean;
var
  extcode: cardinal;
  extnames: TPUTF8CharDynArray;
  i: PtrInt;
begin
  WR.AddClassName(Context.EClass);
  if (Context.ELevel = sllException) and (Context.EInstance <> nil) and
     (Context.EClass <> EExternalException) then
  begin
    extcode := Context.AdditionalInfo(extnames);
    if extcode <> 0 then
    begin
      WR.AddShorter(' 0x');
      WR.AddBinToHexDisplayLower(@extcode, SizeOf(extcode));
      for i := 0 to high(extnames) do
      begin
        {$ifdef MSWINDOWS}
        WR.AddShort(' [.NET/CLR unhandled ');
        {$else}
        WR.AddShort(' [unhandled ');
        {$endif MSWINDOWS}
        WR.AddNoJSONEScape(extnames[i]);
        WR.AddShort('Exception]');
      end;
    end;
    WR.Add(' ');
    if WR.ClassType = TBaseWriter then
      {$ifdef UNICODE}
      WR.AddOnSameLineW(pointer(Context.EInstance.Message), 0)
      {$else}
      WR.AddOnSameLine(pointer(Context.EInstance.Message))
      {$endif UNICODE}
    else
      WR.WriteObject(Context.EInstance);
  end
  else if Context.ECode <> 0 then
  begin
    WR.AddShort(' (');
    WR.AddPointer(Context.ECode);
    WR.AddShort(')');
  end;
  result := false; // caller should append "at EAddr" and the stack trace
end;

function ESynException.CustomLog(WR: TBaseWriter;
  const Context: TSynLogExceptionContext): boolean;
begin
  if Assigned(TSynLogExceptionToStrCustom) then
    result := TSynLogExceptionToStrCustom(WR, Context)
  else
    result := DefaultSynLogExceptionToStr(WR, Context);
end;

{$endif NOEXCEPTIONINTERCEPT}


{ **************** Hexadecimal Text And Binary Conversion }

procedure BinToHex(Bin, Hex: PAnsiChar; BinBytes: integer);
var {$ifdef CPUX86NOTPIC}
    tab: TAnsiCharToWord absolute TwoDigitsHexW;
    {$else}
    tab: ^TAnsiCharToWord; // faster on PIC, ARM and x86_64
    {$endif}
begin
  {$ifndef CPUX86NOTPIC} tab := @TwoDigitsHexW; {$endif}
  if BinBytes > 0 then
    repeat
      PWord(Hex)^ := tab[Bin^];
      inc(Bin);
      inc(Hex, 2);
      dec(BinBytes);
    until BinBytes = 0;
end;

function BinToHex(const Bin: RawByteString): RawUTF8;
var
  L: integer;
begin
  L := length(Bin);
  FastSetString(result, nil, L * 2);
  mormot.core.text.BinToHex(pointer(Bin), pointer(Result), L);
end;

function BinToHex(Bin: PAnsiChar; BinBytes: integer): RawUTF8;
begin
  FastSetString(result, nil, BinBytes * 2);
  mormot.core.text.BinToHex(Bin, pointer(Result), BinBytes);
end;

function HexToBin(const Hex: RawUTF8): RawByteString;
var
  L: integer;
begin
  result := '';
  L := length(Hex);
  if L and 1 <> 0 then
    L := 0
  else // hexadecimal should be in char pairs
    L := L shr 1;
  SetLength(result, L);
  if not mormot.core.text.HexToBin(pointer(Hex), pointer(result), L) then
    result := '';
end;

function ByteToHex(P: PAnsiChar; Value: byte): PAnsiChar;
begin
  PWord(P)^ := TwoDigitsHexWB[Value];
  result := P + 2;
end;

procedure BinToHexDisplay(Bin, Hex: PAnsiChar; BinBytes: integer);
var {$ifdef CPUX86NOTPIC}
    tab: TAnsiCharToWord absolute TwoDigitsHexW;
    {$else}
    tab: ^TAnsiCharToWord; // faster on PIC, ARM and x86_64
    {$endif}
begin
  {$ifndef CPUX86NOTPIC} tab := @TwoDigitsHexW; {$endif}
  inc(Hex, BinBytes * 2);
  if BinBytes > 0 then
    repeat
      dec(Hex, 2);
      PWord(Hex)^ := tab[Bin^];
      inc(Bin);
      dec(BinBytes);
    until BinBytes = 0;
end;

function BinToHexDisplay(Bin: PAnsiChar; BinBytes: integer): RawUTF8;
begin
  FastSetString(result, nil, BinBytes * 2);
  BinToHexDisplay(Bin, pointer(result), BinBytes);
end;

procedure BinToHexLower(Bin, Hex: PAnsiChar; BinBytes: integer);
var {$ifdef CPUX86NOTPIC}
    tab: TAnsiCharToWord absolute TwoDigitsHexWLower;
    {$else}
    tab: ^TAnsiCharToWord; // faster on PIC, ARM and x86_64
    {$endif}
begin
  {$ifndef CPUX86NOTPIC} tab := @TwoDigitsHexWLower; {$endif}
  if BinBytes > 0 then
    repeat
      PWord(Hex)^ := tab[Bin^];
      inc(Bin);
      inc(Hex, 2);
      dec(BinBytes);
    until BinBytes = 0;
end;

function BinToHexLower(const Bin: RawByteString): RawUTF8;
begin
  BinToHexLower(pointer(Bin), length(Bin), result);
end;

procedure BinToHexLower(Bin: PAnsiChar; BinBytes: integer; var result: RawUTF8);
begin
  FastSetString(result, nil, BinBytes * 2);
  BinToHexLower(Bin, pointer(result), BinBytes);
end;

function BinToHexLower(Bin: PAnsiChar; BinBytes: integer): RawUTF8;
begin
  BinToHexLower(Bin, BinBytes, result);
end;

procedure BinToHexDisplayLower(Bin, Hex: PAnsiChar; BinBytes: PtrInt);
var {$ifdef CPUX86NOTPIC}
     tab: TAnsiCharToWord absolute TwoDigitsHexWLower;
    {$else}
     tab: ^TAnsiCharToWord; // faster on PIC, ARM and x86_64
    {$endif}
begin
  if (Bin = nil) or (Hex = nil) or (BinBytes <= 0) then
    exit;
  {$ifndef CPUX86NOTPIC} tab := @TwoDigitsHexWLower; {$endif}
  inc(Hex, BinBytes * 2);
  repeat
    dec(Hex, 2);
    PWord(Hex)^ := tab[Bin^];
    inc(Bin);
    dec(BinBytes);
  until BinBytes = 0;
end;

function BinToHexDisplayLower(Bin: PAnsiChar; BinBytes: integer): RawUTF8;
begin
  FastSetString(result, nil, BinBytes * 2);
  BinToHexDisplayLower(Bin, pointer(result), BinBytes);
end;

function BinToHexDisplayLowerShort(Bin: PAnsiChar; BinBytes: integer): shortstring;
begin
  if BinBytes > 127 then
    BinBytes := 127;
  result[0] := AnsiChar(BinBytes * 2);
  BinToHexDisplayLower(Bin, @result[1], BinBytes);
end;

function BinToHexDisplayLowerShort16(Bin: Int64; BinBytes: integer): TShort16;
begin
  if BinBytes > 8 then
    BinBytes := 8;
  result[0] := AnsiChar(BinBytes * 2);
  BinToHexDisplayLower(@Bin, @result[1], BinBytes);
end;

{$ifdef UNICODE}
function BinToHexDisplayFile(Bin: PAnsiChar; BinBytes: integer): TFileName;
var
  temp: TSynTempBuffer;
begin
  temp.Init(BinBytes * 2);
  BinToHexDisplayLower(Bin, temp.Buf, BinBytes);
  Ansi7ToString(PWinAnsiChar(temp.buf), BinBytes * 2, string(result));
  temp.Done;
end;
{$else}
function BinToHexDisplayFile(Bin: PAnsiChar; BinBytes: integer): TFileName;
begin
  SetString(result, nil, BinBytes * 2);
  BinToHexDisplayLower(Bin, pointer(result), BinBytes);
end;
{$endif UNICODE}

procedure PointerToHex(aPointer: Pointer; var result: RawUTF8);
begin
  FastSetString(result, nil, SizeOf(Pointer) * 2);
  BinToHexDisplay(@aPointer, pointer(result), SizeOf(Pointer));
end;

function PointerToHex(aPointer: Pointer): RawUTF8;
begin
  FastSetString(result, nil, SizeOf(aPointer) * 2);
  BinToHexDisplay(@aPointer, pointer(result), SizeOf(aPointer));
end;

function CardinalToHex(aCardinal: Cardinal): RawUTF8;
begin
  FastSetString(result, nil, SizeOf(aCardinal) * 2);
  BinToHexDisplay(@aCardinal, pointer(result), SizeOf(aCardinal));
end;

function CardinalToHexLower(aCardinal: Cardinal): RawUTF8;
begin
  FastSetString(result, nil, SizeOf(aCardinal) * 2);
  BinToHexDisplayLower(@aCardinal, pointer(result), SizeOf(aCardinal));
end;

function Int64ToHex(aInt64: Int64): RawUTF8;
begin
  FastSetString(result, nil, SizeOf(Int64) * 2);
  BinToHexDisplay(@aInt64, pointer(result), SizeOf(Int64));
end;

procedure Int64ToHex(aInt64: Int64; var result: RawUTF8);
begin
  FastSetString(result, nil, SizeOf(Int64) * 2);
  BinToHexDisplay(@aInt64, pointer(result), SizeOf(Int64));
end;

function PointerToHexShort(aPointer: Pointer): TShort16;
begin
  result[0] := AnsiChar(SizeOf(aPointer) * 2);
  BinToHexDisplay(@aPointer, @result[1], SizeOf(aPointer));
end;

function CardinalToHexShort(aCardinal: Cardinal): TShort16;
begin
  result[0] := AnsiChar(SizeOf(aCardinal) * 2);
  BinToHexDisplay(@aCardinal, @result[1], SizeOf(aCardinal));
end;

function Int64ToHexShort(aInt64: Int64): TShort16;
begin
  result[0] := AnsiChar(SizeOf(aInt64) * 2);
  BinToHexDisplay(@aInt64, @result[1], SizeOf(aInt64));
end;

procedure Int64ToHexShort(aInt64: Int64; out result: TShort16);
begin
  result[0] := AnsiChar(SizeOf(aInt64) * 2);
  BinToHexDisplay(@aInt64, @result[1], SizeOf(aInt64));
end;

function Int64ToHexString(aInt64: Int64): string;
var
  temp: TShort16;
begin
  Int64ToHexShort(aInt64, temp);
  Ansi7ToString(@temp[1], ord(temp[0]), result);
end;

function HexDisplayToBin(Hex: PAnsiChar; Bin: PByte; BinBytes: integer): boolean;
var
  b, c: byte;
  {$ifdef CPUX86NOTPIC}
  tab: TNormTableByte absolute ConvertHexToBin;
  {$else}
  tab: PNormTableByte; // faster on PIC, ARM and x86_64
  {$endif}
begin
  result := false; // return false if any invalid char
  if (Hex = nil) or (Bin = nil) then
    exit;
  {$ifndef CPUX86NOTPIC} tab := @ConvertHexToBin; {$endif}
  if BinBytes > 0 then
  begin
    inc(Bin, BinBytes - 1);
    repeat
      b := tab[Ord(Hex[0])];
      c := tab[Ord(Hex[1])];
      if (b > 15) or (c > 15) then
        exit;
      b := b shl 4; // better FPC generation code in small explicit steps
      b := b or c;
      Bin^ := b;
      dec(Bin);
      inc(Hex, 2);
      dec(BinBytes);
    until BinBytes = 0;
  end;
  result := true; // correct content in Hex
end;

function HexDisplayToCardinal(Hex: PAnsiChar; out aValue: cardinal): boolean;
begin
  result := HexDisplayToBin(Hex, @aValue, SizeOf(aValue));
  if not result then
    aValue := 0;
end;

function HexDisplayToInt64(Hex: PAnsiChar; out aValue: Int64): boolean;
begin
  result := HexDisplayToBin(Hex, @aValue, SizeOf(aValue));
  if not result then
    aValue := 0;
end;

function HexDisplayToInt64(const Hex: RawByteString): Int64;
begin
  if not HexDisplayToBin(pointer(Hex), @result, SizeOf(result)) then
    result := 0;
end;

function HexToBin(Hex: PAnsiChar; Bin: PByte; BinBytes: Integer): boolean;
var
  b, c: byte;
  {$ifdef CPUX86NOTPIC}
  tab: TNormTableByte absolute ConvertHexToBin;
  {$else}
  tab: PNormTableByte; // faster on PIC, ARM and x86_64
  {$endif}
begin
  result := false; // return false if any invalid char
  if Hex = nil then
    exit;
  {$ifndef CPUX86NOTPIC} tab := @ConvertHexToBin; {$endif}
  if BinBytes > 0 then
    if Bin <> nil then
      repeat
        b := tab[Ord(Hex[0])];
        c := tab[Ord(Hex[1])];
        if (b > 15) or (c > 15) then
          exit;
        inc(Hex, 2);
        b := b shl 4;
        b := b or c;
        Bin^ := b;
        inc(Bin);
        dec(BinBytes);
      until BinBytes = 0
    else
      repeat // Bin=nil -> validate Hex^ input
        if (tab[Ord(Hex[0])] > 15) or (tab[Ord(Hex[1])] > 15) then
          exit;
        inc(Hex, 2);
        dec(BinBytes);
      until BinBytes = 0;
  result := true; // conversion OK
end;

procedure HexToBinFast(Hex: PAnsiChar; Bin: PByte; BinBytes: Integer);
var
  {$ifdef CPUX86NOTPIC}
  tab: TNormTableByte absolute ConvertHexToBin;
  {$else}
  tab: PNormTableByte; // faster on PIC, ARM and x86_64
  {$endif}
  c: byte;
begin
  {$ifndef CPUX86NOTPIC} tab := @ConvertHexToBin; {$endif}
  if BinBytes > 0 then
    repeat
      c := tab[ord(Hex[0])];
      c := c shl 4;
      c := tab[ord(Hex[1])] or c;
      Bin^ := c;
      inc(Hex, 2);
      inc(Bin);
      dec(BinBytes);
    until BinBytes = 0;
end;

function IsHex(const Hex: RawByteString; BinBytes: integer): boolean;
begin
  result := (length(Hex) = BinBytes * 2) and
    mormot.core.text.HexToBin(pointer(Hex), nil, BinBytes);
end;

function HexToCharValid(Hex: PAnsiChar): boolean;
begin
  result := (ConvertHexToBin[Ord(Hex[0])] <= 15) and
            (ConvertHexToBin[Ord(Hex[1])] <= 15);
end;

function HexToChar(Hex: PAnsiChar; Bin: PUTF8Char): boolean;
var
  B, C: PtrUInt;
  {$ifdef CPUX86NOTPIC}
  tab: TNormTableByte absolute ConvertHexToBin;
  {$else}
  tab: PNormTableByte; // faster on PIC, ARM and x86_64
  {$endif}
begin
  if Hex <> nil then
  begin
    {$ifndef CPUX86NOTPIC} tab := @ConvertHexToBin; {$endif}
    B := tab[Ord(Hex[0])];
    C := tab[Ord(Hex[1])];
    if (B <= 15) and (C <= 15) then
    begin
      if Bin <> nil then
        Bin^ := AnsiChar(B shl 4 + C);
      result := true;
      exit;
    end;
  end;
  result := false; // return false if any invalid char
end;

function HexToWideChar(Hex: PAnsiChar): cardinal;
var
  B: PtrUInt;
begin
  result := ConvertHexToBin[Ord(Hex[0])];
  if result <= 15 then
  begin
    B := ConvertHexToBin[Ord(Hex[1])];
    if B <= 15 then
    begin
      result := result shl 4 + B;
      B := ConvertHexToBin[Ord(Hex[2])];
      if B <= 15 then
      begin
        result := result shl 4 + B;
        B := ConvertHexToBin[Ord(Hex[3])];
        if B <= 15 then
        begin
          result := result shl 4 + B;
          exit;
        end;
      end;
    end;
  end;
  result := 0;
end;

function Int18ToChars3(Value: cardinal): RawUTF8;
begin
  FastSetString(result, nil, 3);
  PCardinal(result)^ := ((Value shr 12) and $3f) or ((Value shr 6) and $3f) shl 8 or
                         (Value and $3f) shl 16 + $202020;
end;

procedure Int18ToChars3(Value: cardinal; var result: RawUTF8);
begin
  FastSetString(result, nil, 3);
  PCardinal(result)^ := ((Value shr 12) and $3f) or ((Value shr 6) and $3f) shl 8 or
                         (Value and $3f) shl 16 + $202020;
end;

function Chars3ToInt18(P: pointer): cardinal;
begin
  result := PCardinal(P)^ - $202020;
  result := ((result shr 16) and $3f) or ((result shr 8) and $3f) shl 6 or
            (result and $3f) shl 12;
end;

function IP4Text(ip4: cardinal): shortstring;
var
  b: array[0..3] of byte absolute ip4;
begin
  if ip4 = 0 then
    result := ''
  else
    FormatShort('%.%.%.%', [b[0], b[1], b[2], b[3]], result);
end;

procedure IP6Text(ip6: PHash128; result: PShortString);
var
  i: integer;
  p: PByte;
  tab: ^TByteToWord;
begin
  if IsZero(ip6^) then
    result^ := ''
  else
  begin
    result^[0] := AnsiChar(39);
    p := @result^[1];
    tab := @TwoDigitsHexWBLower;
    for i := 0 to 7 do
    begin
      PWord(p)^ := tab[ip6^[0]];
      inc(p, 2);
      PWord(p)^ := tab[ip6^[1]];
      inc(p, 2);
      inc(PWord(ip6));
      p^ := ord(':');
      inc(p);
    end;
  end;
end;

function IP6Text(ip6: PHash128): shortstring;
begin
  IP6Text(ip6, @result);
end;

function IPToCardinal(P: PUTF8Char; out aValue: cardinal): boolean;
var
  i, c: cardinal;
  b: array[0..3] of byte;
begin
  aValue := 0;
  result := false;
  if (P = nil) or (IdemPChar(P, '127.0.0.1') and (P[9] = #0)) then
    exit;
  for i := 0 to 3 do
  begin
    c := GetNextItemCardinal(P, '.');
    if (c > 255) or ((P = nil) and (i < 3)) then
      exit;
    b[i] := c;
  end;
  if PCardinal(@b)^ <> $0100007f then
  begin
    aValue := PCardinal(@b)^;
    result := true;
  end;
end;

function IPToCardinal(const aIP: RawUTF8; out aValue: cardinal): boolean;
begin
  result := IPToCardinal(pointer(aIP), aValue);
end;

function IPToCardinal(const aIP: RawUTF8): cardinal;
begin
  IPToCardinal(pointer(aIP), result);
end;

function IsValidIP4Address(P: PUTF8Char): boolean;
var
  ndot: PtrInt;
  V: PtrUInt;
begin
  result := false;
  if (P = nil) or not (P^ in ['0'..'9']) then
    exit;
  V := 0;
  ndot := 0;
  repeat
    case P^ of
      #0:
        break;
      '.':
        if (P[-1] = '.') or (V > 255) then
          exit
        else
        begin
          inc(ndot);
          V := 0;
        end;
      '0'..'9':
        V := (V * 10) + ord(P^) - 48;
    else
      exit;
    end;
    inc(P);
  until false;
  if (ndot = 3) and (V <= 255) and (P[-1] <> '.') then
    result := true;
end;

function GUIDToText(P: PUTF8Char; guid: PByteArray): PUTF8Char;
var
  i: integer;
begin // encode as '3F2504E0-4F89-11D3-9A0C-0305E82C3301'
  for i := 3 downto 0 do
  begin
    PWord(P)^ := TwoDigitsHexWB[guid[i]];
    inc(P, 2);
  end;
  inc(PByte(guid), 4);
  for i := 1 to 2 do
  begin
    P[0] := '-';
    PWord(P + 1)^ := TwoDigitsHexWB[guid[1]];
    PWord(P + 3)^ := TwoDigitsHexWB[guid[0]];
    inc(PByte(guid), 2);
    inc(P, 5);
  end;
  P[0] := '-';
  PWord(P + 1)^ := TwoDigitsHexWB[guid[0]];
  PWord(P + 3)^ := TwoDigitsHexWB[guid[1]];
  P[5] := '-';
  inc(PByte(guid), 2);
  inc(P, 6);
  for i := 0 to 5 do
  begin
    PWord(P)^ := TwoDigitsHexWB[guid[i]];
    inc(P, 2);
  end;
  result := P;
end;

function GUIDToRawUTF8(const guid: TGUID): RawUTF8;
var
  P: PUTF8Char;
begin
  FastSetString(result, nil, 38);
  P := pointer(result);
  P^ := '{';
  GUIDToText(P + 1, @guid)^ := '}';
end;

function ToUTF8(const guid: TGUID): RawUTF8;
begin
  FastSetString(result, nil, 36);
  GUIDToText(pointer(result), @guid);
end;

function GUIDToShort(const guid: TGUID): TGUIDShortString;
begin
  GUIDToShort(guid, result);
end;

procedure GUIDToShort(const guid: TGUID; out dest: TGUIDShortString);
begin
  dest[0] := #38;
  dest[1] := '{';
  dest[38] := '}';
  GUIDToText(@dest[2], @guid);
end;

{$ifdef UNICODE}
function GUIDToString(const guid: TGUID): string;
var
  tmp: array[0..35] of AnsiChar;
  i: integer;
begin
  GUIDToText(tmp, @guid);
  SetString(result, nil, 38);
  PWordArray(result)[0] := ord('{');
  for i := 1 to 36 do
    PWordArray(result)[i] := ord(tmp[i - 1]); // no conversion for 7 bit Ansi
  PWordArray(result)[37] := ord('}');
end;
{$else}
function GUIDToString(const guid: TGUID): string;
begin
  result := GUIDToRawUTF8(guid);
end;
{$endif UNICODE}

function HexaToByte(P: PUTF8Char; var Dest: byte): boolean;
  {$ifdef HASINLINE} inline;{$endif}
var
  B, C: PtrUInt;
begin
  B := ConvertHexToBin[Ord(P[0])];
  if B <= 15 then
  begin
    C := ConvertHexToBin[Ord(P[1])];
    if C <= 15 then
    begin
      Dest := B shl 4 + C;
      result := true;
      exit;
    end;
  end;
  result := false; // mark error
end;

function TextToGUID(P: PUTF8Char; guid: PByteArray): PUTF8Char;
var
  i: PtrInt;
begin // decode from '3F2504E0-4F89-11D3-9A0C-0305E82C3301'
  result := nil;
  for i := 3 downto 0 do
  begin
    if not HexaToByte(P, guid[i]) then
      exit;
    inc(P, 2);
  end;
  inc(PByte(guid), 4);
  for i := 1 to 2 do
  begin
    if (P^ <> '-') or not HexaToByte(P + 1, guid[1]) or
       not HexaToByte(P + 3, guid[0]) then
      exit;
    inc(P, 5);
    inc(PByte(guid), 2);
  end;
  if (P[0] <> '-') or (P[5] <> '-') or not HexaToByte(P + 1, guid[0]) or
     not HexaToByte(P + 3, guid[1]) then
    exit;
  inc(PByte(guid), 2);
  inc(P, 6);
  for i := 0 to 5 do
    if HexaToByte(P, guid[i]) then
      inc(P, 2)
    else
      exit;
  result := P;
end;


function StreamToRawByteString(aStream: TStream): RawByteString;
var
  current, size: Int64;
begin
  result := '';
  if aStream = nil then
    exit;
  current := aStream.Position;
  if (current = 0) and aStream.InheritsFrom(TRawByteStringStream) then
  begin
    result := TRawByteStringStream(aStream).DataString; // fast COW
    exit;
  end;
  size := aStream.Size - current;
  if (size = 0) or (size > maxInt) then
    exit;
  SetLength(result, size);
  aStream.Read(pointer(result)^, size);
  aStream.Position := current;
end;

function RawByteStringToStream(const aString: RawByteString): TStream;
begin
  result := TRawByteStringStream.Create(aString);
end;

function ReadStringFromStream(S: TStream; MaxAllowedSize: integer): RawUTF8;
var
  L: integer;
begin
  result := '';
  L := 0;
  if (S.Read(L, 4) <> 4) or (L <= 0) or (L > MaxAllowedSize) then
    exit;
  FastSetString(result, nil, L);
  if S.Read(pointer(result)^, L) <> L then
    result := '';
end;

function WriteStringToStream(S: TStream; const Text: RawUTF8): boolean;
var
  L: integer;
begin
  L := length(Text);
  if L = 0 then
    result := S.Write(L, 4) = 4
  else
    {$ifdef FPC}
    result := (S.Write(L, 4) = 4) and (S.Write(pointer(Text)^, L) = L);
    {$else}
    result := S.Write(pointer(PtrInt(Text) - SizeOf(integer))^, L + 4) = L + 4;
    {$endif FPC}
end;



procedure InitializeUnit;
var
  i: PtrInt;
  v: byte;
  P: PAnsiChar;
  tmp: array[0..15] of AnsiChar;
const
  HexChars:      array[0..15] of AnsiChar = '0123456789ABCDEF';
  HexCharsLower: array[0..15] of AnsiChar = '0123456789abcdef';
begin
  // initialize internal lookup tables for various text conversions
  for i := 0 to 255 do
  begin
    TwoDigitsHex[i][1] := HexChars[i shr 4];
    TwoDigitsHex[i][2] := HexChars[i and $f];
    TwoDigitsHexLower[i][1] := HexCharsLower[i shr 4];
    TwoDigitsHexLower[i][2] := HexCharsLower[i and $f];
  end;
  {$ifdef DOUBLETOSHORT_USEGRISU}
  MoveFast(TwoDigitLookup[0], TwoDigitByteLookupW[0], SizeOf(TwoDigitLookup));
  for i := 0 to 199 do
    dec(PByteArray(@TwoDigitByteLookupW)[i], ord('0')); // '0'..'9' -> 0..9
  {$endif DOUBLETOSHORT_USEGRISU}
  FillcharFast(ConvertHexToBin[0], SizeOf(ConvertHexToBin), 255); // all to 255
  v := 0;
  for i := ord('0') to ord('9') do
  begin
    ConvertHexToBin[i] := v;
    inc(v);
  end;
  for i := ord('A') to ord('F') do
  begin
    ConvertHexToBin[i] := v;
    ConvertHexToBin[i+(ord('a') - ord('A'))] := v;
    inc(v);
  end;
  for i := 0 to high(SmallUInt32UTF8) do
  begin
    P := StrUInt32(@tmp[15], i);
    FastSetString(SmallUInt32UTF8[i], P, @tmp[15] - P);
  end;
end;

initialization
  InitializeUnit;

finalization
end.

