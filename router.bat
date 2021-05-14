@echo off
set domain_name="<your_domain>"
set mask="<network_mask>"

route print | find "<domain_ip if route exists>" > nul
if %errorlevel%==0 echo DEBUG: Route exists && exit /b %errorlevel%

:main
ping -n 1 %domain_name% | find "TTL=" > nul
if %errorlevel%==0 call :get_ip else echo ERROR: Can't resolve %domain_name% && exit /b %errorlevel%
exit /b %errorlevel%

:get_ip
for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 %domain_name% ^| findstr [') do set domain_ip=%%a
echo DEBUG: Domain IP: %domain_ip%
call :get_interface_id
exit /b %errorlevel%

:get_interface_id
ipconfig|find /i "VPN" > nul
if %errorlevel% NEQ 0 echo ERROR: VPN is down, check your connection && exit /b %errorlevel%
for /f "tokens=1" %%a in ('route PRINT ^| findstr VPN') do set vpn_id=%%a
set vpn_id=%vpn_id:.=%
set vpn_id=%vpn_id:VPN=%
echo DEBUG: VPD ID: %vpn_id%
call :get_interface_ip
exit /b %errorlevel%

:get_interface_ip
for /f "tokens=2 delims= " %%i  in ('netsh interface ip show config name^="VPN" ^| findstr "IP"') do set network_ip=%%i
echo DEBUG: NETWORK IP: %network_ip%
call :add_route
exit /b %errorlevel%

:add_route
for /f "delims=" %%A in ('route add %domain_ip% mask %mask% %network_ip% IF %vpn_id% 2^>nul') do set "status=%%A"
echo DEBUG: STATUS:%status%
if %status% == " OK" echo ERROR: Can't add route && exit /b %errorlevel%
exit /b %errorlevel%
