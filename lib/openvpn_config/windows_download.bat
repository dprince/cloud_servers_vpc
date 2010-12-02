cd c:\

ECHO off

ECHO Function download^(Url, File^) > script.vbs
ECHO WScript.Echo "Downloading " ^& Url >> script.vbs
ECHO Set Http = CreateObject^("WinHttp.WinHttpRequest.5.1"^) >> script.vbs
ECHO Http.Open "GET", Url, False >> script.vbs
ECHO Http.Send >> script.vbs
ECHO Set BinaryStream = CreateObject^("ADODB.Stream"^) >> script.vbs
ECHO BinaryStream.Type = 1 >> script.vbs
ECHO BinaryStream.Open >> script.vbs
ECHO BinaryStream.Write Http.ResponseBody >> script.vbs
ECHO BinaryStream.SaveToFile File, 2 >> script.vbs
ECHO BinaryStream.Close >> script.vbs
ECHO END Function >> script.vbs

ECHO download "http://c2865862.cdn.cloudfiles.rackspacecloud.com/openvpn-2.1.3-install.exe", "openvpn-install.exe" >> script.vbs

ECHO download "http://c2865862.cdn.cloudfiles.rackspacecloud.com/AutoIt3_x64.exe", "AutoIt3.exe" >> script.vbs

cscript //nologo c:/script.vbs
