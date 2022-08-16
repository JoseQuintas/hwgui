@echo off
REM
REM sample batch to add binary files in an
REM existing binary container.
REM
REM Modify to your own needs
for /R %%f in (*.bmp) do (
 addbatitem.exe flaggen.bin "%%f"
)
REM =============== EOF of sample.bat =========================