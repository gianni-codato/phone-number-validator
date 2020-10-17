:: curl -d "loginName=codato&password=gianni" -X POST http://localhost:3000/authenticate

:: curl -d "id=123&number=27123123123" -X POST http://localhost:3000/checkSingleNumber

:: curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb2dpbk5hbWUiOiJjb2RhdG8ifQ.2WitgMqh2bKGYVxY_4l2O7hLjJfuQLn4RmHonDMu6uU" -d "id=123" -X GET http://localhost:3000/getSingleNumberById
:: curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb2dpbk5hbWUiOiJjb2RhdG8ifQ.2WitgMqh2bKGYVxY_4l2O7hLjJfuQLn4RmHonDMu6uU" -d "id=123" -X GET http://localhost:3000/getSingleNumberAuditById

:: curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb2dpbk5hbWUiOiJjb2RhdG8ifQ.2WitgMqh2bKGYVxY_4l2O7hLjJfuQLn4RmHonDMu6uU" -d "id=123&number=27123123123" -X POST http://localhost:3000/checkSingleNumber
