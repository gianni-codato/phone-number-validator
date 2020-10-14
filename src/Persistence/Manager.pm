package Persistence::Manager;

# in a real application the sub should return a connection taken from a pool or
# create a new connection, using connection parameters (host, port, username, password, etc)
# from some secret manager or secure ad-hoc storage; this is a "demo" app... so we use a 
# "non persistent persistence layer :-)"
sub getConnection
{   return 
};