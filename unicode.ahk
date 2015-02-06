#SingleInstance force
#NoEnv

F12::
	uc := GetUnicodeNumber("1")
	Send {U+%uc%}
	return

; GetUnicodeNumber by nnik
GetUnicodeNumber(Char)
{
  static Buffer:="" , Init:=VarSetCapacity(Buffer,4,0)
  StrPut(Char,&Buffer,1,"UTF-16")
  return Format("{:x}",NumGet(Buffer,"UInt"))
}
