package Utils::Config;
# this package is a very minimal "configuration manager"; the configuration is read from environment variables
# 
# in a real production environment the application configuration maybe resides in a "secure
# store" (a secure db, a protected ini/yaml/json file, an ad-hoc service...), but in this 
# simple project I wrote this  class only to avoid external dependencies


# retrieve and return the value of the environment variable named $envVarName, if it exits;
# return the value specified in $defaultValue if the variable doesn't exists
my $get_env_entry_with_default = sub
{   my($envVarName, $defaultValue) = @_;

    if (exists($ENV{$envVarName}))
    {   return $ENV{$envVarName};
    }
    return $defaultValue;
};



my $mode = 'prod'; # develop/prod
sub getMode 
{   return $mode;
}
sub setDevelopMode { $mode = 'develop'; }
sub setProdMode    { $mode = 'prod'; }



sub getLogDir
{   return $get_env_entry_with_default->('PHONE_NUMBER_LOG_DIR', 'work/log');
}
sub getLogLevel
{   return $get_env_entry_with_default->('PHONE_NUMBER_LOG_LEVEL', (getMode() eq 'develop' ? 'debug' : 'info'));
}


sub getValidatorName
{   return $get_env_entry_with_default->('PHONE_NUMBER_VALIDATOR', 'standard');
}


sub getDataSourceDir
{   return $get_env_entry_with_default->('PHONE_NUMBER_DATASOURCE_DIR', 'work/data');
}


sub getDefaultLanguageCode
{   return $get_env_entry_with_default->('PHONE_NUMBER_DEFAULT_LANGUAGE_CODE', 'en-US');
}



sub getSrcDir
{   return $get_env_entry_with_default->('PHONE_NUMBER_SRC_DIR', 'src');
}

1;
