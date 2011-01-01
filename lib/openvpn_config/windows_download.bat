cd c:\

ECHO off

ECHO Function download^(Url, File^) > script.vbs
ECHO Set WinHttpReq = CreateObject^("WinHttp.WinHttpRequest.5.1"^) >> script.vbs
ECHO WinHttpReq.SetTimeouts 30000, 30000, 70000, 70000 >> script.vbs
ECHO WinHttpReq.Open "GET", Url, False >> script.vbs
ECHO WinHttpReq.Send >> script.vbs
ECHO Set BinaryStream = CreateObject^("ADODB.Stream"^) >> script.vbs
ECHO BinaryStream.Type = 1 >> script.vbs
ECHO BinaryStream.Open >> script.vbs
ECHO BinaryStream.Write WinHttpReq.ResponseBody >> script.vbs
ECHO BinaryStream.SaveToFile File, 2 >> script.vbs
ECHO BinaryStream.Close >> script.vbs
ECHO END Function >> script.vbs

ECHO download "http://c2865862.cdn.cloudfiles.rackspacecloud.com/openvpn-2.1.3-install.exe", "openvpn-install.exe" >> script.vbs

ECHO download "http://c2865862.cdn.cloudfiles.rackspacecloud.com/openvpn.cer", "openvpn.cer" >> script.vbs

cscript c:\script.vbs
del c:\script.vbs
