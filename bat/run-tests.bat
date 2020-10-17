:: this batch supposes to be launched from the root of the project, typing at the prompt:
:: bat\run-tests.bat

SET PHONE_NUMBER_SRC_DIR=src

:: don't change the following env vars: they are used to configure the server,
:: not the tests (they are here only to reset the value to the default)
SET PHONE_NUMBER_LOG_LEVEL=debug
SET PHONE_NUMBER_LOG_DIR=../work/log
SET PHONE_NUMBER_DATASOURCE_DIR=../work/data
SET PHONE_NUMBER_VALIDATOR=standard
SET PHONE_NUMBER_DEFAULT_LANGUAGE_CODE=en-US

prove -Isrc t/
