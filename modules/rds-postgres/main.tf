# TODO: implement in this order during the demo:
#   1. aws_security_group  (port 5432, ingress from 10.0.0.0/8)
#   2. aws_db_subnet_group
#   3. aws_db_parameter_group (postgres15, log_connections=1)
#   4. aws_db_instance        (storage_encrypted=true, sensitive password)
