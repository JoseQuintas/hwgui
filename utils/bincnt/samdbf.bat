@echo off
REM
REM sample batch to add binary files in an
REM existing DBF binary container.
REM
REM Modify to your own needs
for /R %%f in (*.bmp) do (
 adddbfitem.exe flaggen "%%f"
)
REM =============== EOF of samdbf.bat =========================