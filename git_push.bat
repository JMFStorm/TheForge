@echo off
setlocal enabledelayedexpansion

set "timestamp=%DATE% %TIME%"
set /p commitMessage="Enter commit message: "
set "commitMessage=!commitMessage! [!timestamp!]"

git add .
git commit -m "!commitMessage!"
git push origin master

endlocal
