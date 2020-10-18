:: this batch supposes to be launched from the root of the project, typing at the prompt:
:: bat\curl-example.bat


:: call to validate a number, unauthenticated mode
curl -d "id=123&number=27123123123" -X POST http://localhost:3000/v1/checkSingleNumber
pause


:: call for authentication
:: should return: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb2dpbk5hbWUiOiJjb2RhdG8ifQ.2WitgMqh2bKGYVxY_4l2O7hLjJfuQLn4RmHonDMu6uU
curl -d "loginName=codato&password=gianni" -X POST http://localhost:3000/v1/authenticate
pause


SET JWT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb2dpbk5hbWUiOiJjb2RhdG8ifQ.2WitgMqh2bKGYVxY_4l2O7hLjJfuQLn4RmHonDMu6uU


:: call to validate a number, but with authentication (this will write to db)
curl -H "Authorization: Bearer %JWT%" -d "id=123&number=27123123123" -X POST http://localhost:3000/v1/checkSingleNumber
pause


:: call to inspect a single phone number: last (current) value
curl -H "Authorization: Bearer %JWT%" -d "id=123" -X GET http://localhost:3000/v1/getSingleNumberById
:: call to inspect a single phone number: all history (audit data)
curl -H "Authorization: Bearer %JWT%" -d "id=123" -X GET http://localhost:3000/v1/getSingleNumberAuditById
pause


:: call to bulk insert with file
:: \" is because the file name has a spece
SET FILE_NAME=\"t\Pre-selezione. South_African_Mobile_Numbers.csv\"
curl -H "Authorization: Bearer %JWT%" -F "phoneNumbersFile=@%FILE_NAME%" -X POST http://localhost:3000/v1/checkNumbers
pause
