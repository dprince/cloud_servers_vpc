cd c:\
set WIN_TITLE=OpenVPN 2.1.3 Setup

ECHO off

ECHO Run^("openvpn-install.exe"^) > vpn_ui_install.au3
ECHO Sleep^(2000^) >> vpn_ui_install.au3
ECHO WinActivate ^("[CLASS:#32770]", "%TITLE%"^) >> vpn_ui_install.au3

ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(500^) >> vpn_ui_install.au3

ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(500^) >> vpn_ui_install.au3

ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(500^) >> vpn_ui_install.au3

ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(500^) >> vpn_ui_install.au3

ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(10000^) >> vpn_ui_install.au3

ECHO ControlSend^("Windows Security", "", "", "{TAB}"^) >> vpn_ui_install.au3
ECHO ControlSend^("Windows Security", "", "", "{TAB}"^) >> vpn_ui_install.au3
ECHO ControlSend^("Windows Security", "", "", "{TAB}"^) >> vpn_ui_install.au3
ECHO ControlSend^("Windows Security", "", "", "{ENTER}"^) >> vpn_ui_install.au3

ECHO Sleep^(5000^) >> vpn_ui_install.au3

ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(500^) >> vpn_ui_install.au3

ECHO Send^("{SPACE}"^) >> vpn_ui_install.au3
ECHO ControlClick^("[CLASS:#32770]", "", "[CLASS:Button;INSTANCE:2]"^) >> vpn_ui_install.au3
ECHO Sleep^(500^) >> vpn_ui_install.au3

c:\AutoIt3.exe vpn_ui_install.au3
