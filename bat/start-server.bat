:: this batch supposes to be launched from the root of the project, typing at the prompt:
:: bat\start-server.bat

cd src

SET PHONE_NUMBER_SRC_DIR=.
SET PHONE_NUMBER_LOG_DIR=../work/log
SET PHONE_NUMBER_LOG_LEVEL=debug
SET PHONE_NUMBER_DEFAULT_LANGUAGE_CODE=en-US
SET PHONE_NUMBER_DATASOURCE_DIR=../work/data
SET PHONE_NUMBER_VALIDATOR=standardI18n

morbo Rest/App.pl