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



my $mode; # develop/prod
sub getMode 
{   return defined($mode) ? $mode : 'prod';
}
sub setDevelopMode
{   $mode = 'develop';
}



sub getLogDir
{   return $get_env_entry_with_default->('PHONE_NUMBER_LOG_DIR', 'work/log')
}
sub getLogLevel
{   return $get_env_entry_with_default->('PHONE_NUMBER_LOG_LEVEL', 'info')
}


sub getValidatorName
{   return $get_env_entry_with_default->('PHONE_NUMBER_VALIDATOR', 'standard')
}


sub getDataSourceDir
{   return $get_env_entry_with_default->('PHONE_NUMBER_DATASOURCE', 'work/data')
}


1;